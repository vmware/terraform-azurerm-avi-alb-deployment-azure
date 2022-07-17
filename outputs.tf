output "controllers" {
  description = "The AVI Controller(s) Information"
  value = ([for s in azurerm_linux_virtual_machine.avi_controller : merge(
    { "name" = s.name },
    { "private_ip_address" = s.private_ip_address },
    var.controller_public_address ? { "public_ip_address" = s.public_ip_address } : {}
    )
    ]
  )
}
output "controller_private_addresses" {
  description = "The Private IP Addresses allocated for the Avi Controller(s)"
  value       = azurerm_linux_virtual_machine.avi_controller[*].private_ip_address
}
output "controller_resource_group" {
  description = "The Resource Group used for the Avi Controller"
  value       = var.create_resource_group ? azurerm_resource_group.avi[0].name : var.custom_controller_resource_group
}
output "controller_vnet" {
  description = "The VNET that the Avi Controller is deployed to"
  value       = var.create_networking ? azurerm_virtual_network.avi[0].name : var.custom_vnet_name
}