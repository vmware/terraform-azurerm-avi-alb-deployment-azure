terraform {
  required_version = ">= 1.3.0"
  backend "local" {
  }
}
module "avi_controller_azure" {
  source = "../.."

  region                       = "westus2"
  create_marketplace_agreement = false
  name_prefix                  = var.name_prefix
  controller_default_password  = var.controller_default_password
  controller_password          = var.controller_password
  create_networking            = var.create_networking
  create_iam                   = var.create_iam
  controller_ha                = var.controller_ha
  controller_public_address    = var.controller_public_address
  se_ha_mode                   = "active/active"
  vnet_address_space           = "10.255.0.0/16"
  avi_subnet                   = "10.255.0.0/24"
  configure_dns_profile        = var.configure_dns_profile
  configure_dns_vs             = var.configure_dns_vs
  controller_az_app_id         = var.create_iam ? null : var.controller_az_app_id
  controller_az_client_secret  = var.create_iam ? null : var.controller_az_client_secret
}