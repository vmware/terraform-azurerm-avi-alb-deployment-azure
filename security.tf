resource "azurerm_network_security_group" "avi_controller_mgmt" {
  count               = var.create_firewall_rules ? 1 : 0
  name                = "avi_controller_mgmt"
  location            = var.create_resource_group ? azurerm_resource_group.avi[0].location : data.azurerm_resource_group.custom[0].location
  resource_group_name = var.create_resource_group ? azurerm_resource_group.avi[0].name : var.custom_controller_resource_group

  security_rule {
    name                       = "avi_controller_ssh"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
  security_rule {
    name                       = "avi_controller_web"
    priority                   = 200
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
  security_rule {
    name                       = "avi_controller_secure_channel_https"
    priority                   = 300
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "8443"
    source_address_prefix      = "VirtualNetwork"
    destination_address_prefix = "VirtualNetwork"
  }
  security_rule {
    name                       = "avi_controller_ntp"
    priority                   = 400
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Udp"
    source_port_range          = "*"
    destination_port_range     = "123"
    source_address_prefix      = "VirtualNetwork"
    destination_address_prefix = "VirtualNetwork"
  }

  tags = var.custom_tags
}
resource "azurerm_network_interface_security_group_association" "controller" {
  count                     = var.create_firewall_rules ? var.controller_ha ? 3 : 1 : 0
  network_interface_id      = azurerm_network_interface.avi[count.index].id
  network_security_group_id = azurerm_network_security_group.avi_controller_mgmt[0].id
}