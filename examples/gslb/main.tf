terraform {
  required_version = ">= 0.13.6"
  backend "local" {
  }
}
module "avi_controller_azure_westus2" {
  source = "../.."

  region                       = "westus2"
  create_marketplace_agreement = false
  name_prefix                  = var.name_prefix_west
  controller_default_password  = var.controller_default_password
  controller_password          = var.controller_password
  create_networking            = var.create_networking
  create_vnet_peering          = true
  vnet_peering_settings        = { global_peering = true, resource_group = "rg-${var.name_prefix_east}-avi-eastus2", vnet_name = "${var.name_prefix_east}-avi-vnet-eastus2" }
  create_iam                   = var.create_iam
  controller_ha                = var.controller_ha
  controller_public_address    = var.controller_public_address
  custom_tags                  = { "Role" : "Avi-Controller", "Owner" : "slarimore", "Provisioner" : "Terraform" }
  se_ha_mode                   = "active/active"
  vnet_address_space           = "10.251.0.0/16"
  avi_subnet                   = "10.251.0.0/24"
  configure_dns_profile        = true
  dns_service_domain           = "aviwest2.local"
  configure_dns_vs             = true
  dns_vs_allocate_public_ip    = var.controller_public_address
  controller_az_app_id         = var.create_iam ? null : var.controller_az_app_id
  controller_az_client_secret  = var.create_iam ? null : var.controller_az_client_secret
}
module "avi_controller_azure_eastus2" {
  source = "../.."

  region                          = "eastus2"
  create_marketplace_agreement    = false
  name_prefix                     = var.name_prefix_east
  controller_default_password     = var.controller_default_password
  controller_password             = var.controller_password
  create_networking               = true
  create_vnet_peering             = true
  vnet_peering_settings           = { global_peering = true, resource_group = "rg-${var.name_prefix_west}-avi-westus2", vnet_name = "${var.name_prefix_west}-avi-vnet-westus2" }
  create_iam                      = var.create_iam
  controller_ha                   = var.controller_ha
  controller_public_address       = var.controller_public_address
  custom_tags                     = { "Role" : "Avi-Controller", "Owner" : "slarimore", "Provisioner" : "Terraform" }
  se_ha_mode                      = "active/active"
  vnet_address_space              = "10.252.0.0/16"
  avi_subnet                      = "10.252.0.0/24"
  configure_dns_profile           = true
  dns_service_domain              = "avieast2.local"
  configure_dns_vs                = true
  dns_vs_allocate_public_ip       = var.controller_public_address
  configure_gslb                  = true
  gslb_site_name                  = "East2"
  gslb_domains                    = ["avigslb.local"]
  configure_gslb_additional_sites = true
  additional_gslb_sites           = [{ name = "West2", ip_address_list = module.avi_controller_azure_westus2.controllers[*].private_ip_address, dns_vs_name = "DNS-VS" }]
  controller_az_app_id            = var.create_iam ? null : var.controller_az_app_id
  controller_az_client_secret     = var.create_iam ? null : var.controller_az_client_secret
}