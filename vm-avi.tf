locals {
  cloud_settings = {
    subscription_id           = data.azurerm_subscription.current.subscription_id
    se_mgmt_subnet_name       = var.create_networking ? azurerm_subnet.avi[0].name : data.azurerm_subnet.custom[0].name
    se_vnet_id_path           = var.create_networking ? azurerm_virtual_network.avi[0].id : data.azurerm_virtual_network.custom[0].id
    controller_public_address = var.controller_public_address
    avi_version               = local.avi_info[var.avi_version]["api_version"]
    dns_servers               = var.dns_servers
    dns_search_domain         = var.dns_search_domain
    ntp_servers               = var.ntp_servers
    email_config              = var.email_config
    region                    = local.region
    se_vm_size                = var.se_vm_size
    use_azure_dns             = var.use_azure_dns
    se_resource_group         = var.create_resource_group ? azurerm_resource_group.avi[0].name : var.custom_se_resource_group != null ? var.custom_se_resource_group : var.custom_controller_resource_group
    name_prefix               = var.name_prefix
    controller_ha             = var.controller_ha
    register_controller       = var.register_controller
    controller_ip             = local.controller_ip
    controller_names          = local.controller_names
    use_standard_alb          = var.use_standard_alb
    configure_dns_profile     = var.configure_dns_profile
    configure_dns_vs          = local.configure_dns_vs
    configure_gslb            = var.configure_gslb
    se_ha_mode                = var.se_ha_mode
    avi_upgrade               = var.avi_upgrade
  }
  configure_dns_vs = merge(var.configure_dns_vs, local.dns_vs_subnet)
  dns_vs_subnet = {
    subnet_name = var.create_networking ? azurerm_subnet.avi[0].name : var.custom_subnet_name,
  }
  avi_info = {
    "20.1" = {
      "plan"        = "nsx-alb-controller-2001",
      "api_version" = "20.1.6"
    },
    "21.1" = {
      "plan"        = "nsx-alb-controller-2101"
      "api_version" = "21.1.4"
    },
    "22.1" = {
      "plan"        = "nsx-alb-controller-2201"
      "api_version" = "22.1.1"
    }
  }
  region                          = lower(replace(var.region, " ", ""))
  controller_ip                   = azurerm_linux_virtual_machine.avi_controller[*].private_ip_address
  controller_names                = azurerm_linux_virtual_machine.avi_controller[*].name
  regions_with_availability_zones = ["centralus", "eastus2", "eastus", "westus2", "westus3", "southcentralus", "brazilsouth", "canadacentral", "francecentral", "germanywestcentral", "northeurope", "norwayeast", "uksouth", "westeurope", "swedencentral", "switzerlandnorth", "southafricanorth", "australiaeast", "centralindia", "japaneast", "koreacentral", "Southeast Asia", "eastasia", "chinanorth3"]
  zones                           = contains(local.regions_with_availability_zones, local.region) ? true : false
}
resource "azurerm_marketplace_agreement" "avi" {
  count     = var.create_marketplace_agreement ? 1 : 0
  publisher = "avi-networks"
  offer     = "avi-vantage-adc"
  plan      = local.avi_info[var.avi_version]["plan"]
}
resource "azurerm_linux_virtual_machine" "avi_controller" {
  count                           = var.controller_ha ? 3 : 1
  name                            = "${var.name_prefix}-avi-controller-${count.index + 1}"
  resource_group_name             = var.create_resource_group ? azurerm_resource_group.avi[0].name : var.custom_controller_resource_group
  location                        = var.create_resource_group ? azurerm_resource_group.avi[0].location : data.azurerm_resource_group.custom[0].location
  zone                            = local.zones ? count.index + 1 : null
  size                            = var.controller_vm_size
  admin_username                  = "avi-admin"
  admin_password                  = "Password123!"
  disable_password_authentication = false
  network_interface_ids = [
    azurerm_network_interface.avi[count.index].id,
  ]
  identity {
    type = "SystemAssigned"
  }

  source_image_reference {
    publisher = "avi-networks"
    offer     = "avi-vantage-adc"
    sku       = local.avi_info[var.avi_version]["plan"]
    version   = "latest"
  }
  plan {
    name      = local.avi_info[var.avi_version]["plan"]
    publisher = "avi-networks"
    product   = "avi-vantage-adc"
  }
  tags = var.custom_tags

  os_disk {
    storage_account_type = var.controller_disk_type
    caching              = "ReadWrite"
    disk_size_gb         = var.controller_disk_size
  }
  provisioner "local-exec" {
    command = var.controller_public_address ? "bash ${path.module}/files/change-controller-password.sh --controller-address \"${self.public_ip_address}\" --current-password \"${var.controller_default_password}\" --new-password \"${var.controller_password}\"" : "bash ${path.module}/files/change-controller-password.sh --controller-address \"${self.private_ip_address}\" --current-password \"${var.controller_default_password}\" --new-password \"${var.controller_password}\""
  }
  timeouts {
    create = "20m"
    delete = "20m"
  }
  lifecycle {
    create_before_destroy = true
  }
  depends_on = [
    azurerm_marketplace_agreement.avi,
    azurerm_network_interface_security_group_association.controller
  ]
}
resource "null_resource" "ansible_provisioner" {
  # Changes to any instance of the cluster requires re-provisioning
  triggers = {
    controller_instance_ids = join(",", azurerm_linux_virtual_machine.avi_controller.*.id)
  }

  connection {
    type     = "ssh"
    host     = var.controller_public_address ? azurerm_linux_virtual_machine.avi_controller[0].public_ip_address : azurerm_linux_virtual_machine.avi_controller[0].private_ip_address
    user     = "admin"
    timeout  = "600s"
    password = var.controller_password
  }
  provisioner "remote-exec" {
    inline = ["mkdir ansible"]
  }
  provisioner "file" {
    source      = "${path.module}/files/avi_pulse_registration.py"
    destination = "/home/admin/ansible/avi_pulse_registration.py"
  }
  provisioner "file" {
    source      = "${path.module}/files/views_albservices.patch"
    destination = "/home/admin/ansible/views_albservices.patch"
  }
  provisioner "file" {
    content = templatefile("${path.module}/files/avi-controller-azure-all-in-one-play.yml.tpl",
    local.cloud_settings)
    destination = "/home/admin/ansible/avi-controller-azure-all-in-one-play.yml"
  }
  provisioner "file" {
    content = templatefile("${path.module}/files/gslb-add-site-tasks.yml.tpl",
    local.cloud_settings)
    destination = "/home/admin/ansible/gslb-add-site-tasks.yml"
  }
  provisioner "file" {
    content = templatefile("${path.module}/files/avi-cloud-services-registration.yml.tpl",
    local.cloud_settings)
    destination = "/home/admin/ansible/avi-cloud-services-registration.yml"
  }
  provisioner "file" {
    content = templatefile("${path.module}/files/avi-upgrade.yml.tpl",
    local.cloud_settings)
    destination = "/home/admin/ansible/avi-upgrade.yml"
  }
  provisioner "file" {
    content = templatefile("${path.module}/files/avi-cleanup.yml.tpl",
    local.cloud_settings)
    destination = "/home/admin/ansible/avi-cleanup.yml"
  }
  provisioner "remote-exec" {
    inline = var.configure_controller ? var.create_iam ? [
      "cd ansible",
      "ansible-playbook avi-controller-azure-all-in-one-play.yml -e password=${var.controller_password} -e azure_app_id=\"${azuread_application.avi[0].application_id}\" -e azure_auth_token=\"${azuread_application_password.avi[0].value}\" -e azure_tenant_id=\"${data.azurerm_subscription.current.tenant_id}\"  2> ansible-error.log | tee ansible-playbook.log",
      "echo Controller Configuration Completed"
      ] : [
      "cd ansible",
      "ansible-playbook avi-controller-azure-all-in-one-play.yml -e password=${var.controller_password} -e azure_app_id=\"${var.controller_az_app_id}\" -e azure_auth_token=\"${var.controller_az_client_secret}\" -e azure_tenant_id=\"${data.azurerm_subscription.current.tenant_id}\"  2> ansible-error.log | tee ansible-playbook.log",
      "echo Controller Configuration Completed"
      ] : [
      "cd ansible",
      "ansible-playbook avi-controller-azure-all-in-one-play.yml -e password=${var.controller_password} --tags register_controller 2> ansible-error.log | tee ansible-playbook.log",
      "echo Controller Configuration Completed"
    ]
  }
  provisioner "remote-exec" {
    inline = var.register_controller["enabled"] ? [
      "cd ansible",
      "ansible-playbook avi-cloud-services-registration.yml -e password=${var.controller_password} 2>> ansible-error.log | tee -a ansible-playbook.log",
      "echo Controller Registration Completed"
    ] : ["echo Controller Registration Skipped"]
  }
  provisioner "remote-exec" {
    inline = var.avi_upgrade["enabled"] ? [
      "cd ansible",
      "ansible-playbook avi-upgrade.yml -e password=${var.controller_password} -e upgrade_type=${var.avi_upgrade["upgrade_type"]} 2>> ansible-error.log | tee -a ansible-playbook.log",
      "echo Avi upgrade completed"
    ] : ["echo Avi upgrade skipped"]
  }
}
