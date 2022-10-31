variable "controller_default_password" {
  description = "This is the default password for the Avi controller image and can be found in the image download page."
  type        = string
  sensitive   = true
}
variable "controller_password" {
  description = "The password that will be used authenticating with the Avi Controller. This password be a minimum of 8 characters and contain at least one each of uppercase, lowercase, numbers, and special characters"
  type        = string
  sensitive   = true
  validation {
    condition     = length(var.controller_password) > 7
    error_message = "The controller_password value must be more than 8 characters and contain at least one each of uppercase, lowercase, numbers, and special characters."
  }
}
variable "name_prefix_east" {
  description = "This prefix is appended to the names of the Controller and SEs"
  type        = string
}
variable "name_prefix_west" {
  description = "This prefix is appended to the names of the Controller and SEs in Site 2"
  type        = string
}
variable "controller_ha" {
  description = "If true a HA controller cluster is deployed and configured"
  type        = bool
  default     = false
}
variable "create_networking" {
  description = "This variable controls the VPC and subnet creation for the Avi Controller. When set to false the custom_vpc_name and custom_subnetwork_name must be set."
  type        = bool
  default     = true
}
variable "create_iam" {
  description = "Create IAM Roles and Role Bindings necessary for the Avi GCP Full Access Cloud. If not set the Roles and permissions in this document must be associated with the controller service account - https://Avinetworks.com/docs/latest/gcp-full-access-roles-and-permissions/"
  type        = bool
  default     = false
}
variable "configure_dns_vs" {
  description = "Create Avi DNS Virtual Service. The subnet_name parameter must be an existing AWS Subnet. If the allocate_public_ip parameter is set to true a EIP will be allocated for the VS. The VS IP address will automatically be allocated via the AWS IPAM"
  type        = object({ enabled = bool, allocate_public_ip = bool })
  default     = { enabled = "false", allocate_public_ip = "false" }
}
variable "controller_public_address" {
  description = "This variable controls if the Controller has a Public IP Address. When set to false the Ansible provisioner will connect to the private IP of the Controller."
  type        = bool
  default     = true
}
variable "controller_az_app_id" {
  description = "If the create_iam variable is set to false, this is the Azure Application ID that the Avi Controller will use to create Azure resources"
  type        = string
  sensitive   = true
  default     = null
}
variable "controller_az_client_secret" {
  description = "If the create_iam variable is set to false, this is the Azure Client Secret that the Avi Controller will use to create Azure resources"
  type        = string
  sensitive   = true
  default     = null
}