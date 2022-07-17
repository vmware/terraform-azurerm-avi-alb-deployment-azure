data "azurerm_subscription" "current" {}
data "azuread_client_config" "current" {}
data "azurerm_virtual_network" "custom" {
  count               = var.create_networking == false ? 1 : 0
  name                = var.custom_vnet_name
  resource_group_name = var.custom_controller_resource_group
}
data "azurerm_subnet" "custom" {
  count                = var.create_networking == false ? 1 : 0
  name                 = var.custom_subnet_name
  virtual_network_name = var.custom_vnet_name
  resource_group_name  = var.custom_controller_resource_group
}
data "azurerm_resource_group" "custom" {
  count = var.create_resource_group == false ? 1 : 0
  name  = var.custom_controller_resource_group
}