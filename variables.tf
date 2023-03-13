# Copyright 2022 VMware, Inc.
# SPDX-License-Identifier: Apache-2.0

variable "region" {
  description = "The Region that the AVI controller and SEs will be deployed to"
  type        = string
}
variable "create_resource_group" {
  description = "If true a Resource Group is created and used for the AVI Controllers and Service Engines"
  type        = bool
  default     = "true"
}
variable "create_marketplace_agreement" {
  description = "If set to true the user agrees to the terms and conditions for the Avi Marketplace image as found here https://azuremarketplace.microsoft.com/en-us/marketplace/apps/avi-networks.avi-vantage-adc. When multiple instances of this module are used only 1 should have this value set to true to prevent duplicate deployments"
  type        = bool
  default     = "true"
}
variable "license_tier" {
  description = "The license tier to use for Avi. Possible values are ENTERPRISE_WITH_CLOUD_SERVICES or ENTERPRISE"
  type        = string
  default     = "ENTERPRISE_WITH_CLOUD_SERVICES"
  validation {
    condition     = var.license_tier == "ENTERPRISE_WITH_CLOUD_SERVICES" || var.license_tier == "ENTERPRISE"
    error_message = "The license_tier variable must be ENTERPRISE_WITH_CLOUD_SERVICES or ENTERPRISE."
  }
}
variable "license_key" {
  description = "The license key that will be applied when the tier is set to ENTERPRISE with the license_tier variable"
  type        = string
  default     = ""
}
variable "ca_certificates" {
  description = "Import one or more Root or Intermediate Certificate Authority SSL certificates for the controller. The certificate must be in the PEM format and base64 encoded without line breaks. An example command for generating the proper format is 'base64 -w 0 ca.pem > ca.base64'"
  type = list(object({
    name        = string,
    certificate = string,
  }))
  default = [{ name = "", certificate = "" }]
}
variable "portal_certificate" {
  description = "Import a SSL certificate for the controller's web portal. The key and certificate must be in the PEM format and base64 encoded without line breaks. An example command for generating the proper format is 'base64 -w 0 certificate.pem > cert.base64'"
  type = object({
    key            = string,
    certificate    = string,
    key_passphrase = optional(string),
  })
  default = { key = "", certificate = "" }
}
variable "securechannel_certificate" {
  description = "Import a SSL certificate for the controller's secure channel communication. Only if there is strict policy that requires all SSL certificates to be signed a specific CA should this variable be used otherwise the default generated certificate is recommended. The full cert chain is necessary and can be provided within the certificate PEM file or separately with the ca_certificates variable. The key and certificate must be in the PEM format and base64 encoded without line breaks. An example command for generating the proper format is 'base64 -w 0 certificate.pem > cert.base64'"
  type = object({
    key            = string,
    certificate    = string,
    key_passphrase = optional(string),
  })
  default = { key = "", certificate = "" }
}
variable "cluster_ip" {
  description = "Sets the IP address of the Avi Controller cluster. This address must be in the same subnet as the Avi Controller VMs."
  type        = string
  default     = null
}
variable "use_standard_alb" {
  description = "If true the AVI Cloud is configured to use standard SKU for the Azure LBs that route to Avi SEs"
  type        = bool
  default     = "false"
}
variable "use_azure_dns" {
  description = "If true the AVI Cloud is configured to use Azure DNS"
  type        = bool
  default     = "false"
}
variable "custom_se_resource_group" {
  description = "This field can be used to specify an existing Resource Group for Service Engines."
  type        = string
  default     = null
}
variable "custom_controller_resource_group" {
  description = "This field can be used to specify an existing Resource Group for AVI Controllers. The create_resource_group variable must also be set to false for this resource group to be used."
  type        = string
  default     = ""
}
variable "avi_version" {
  description = "The major and minor version of the AVI Controller version that will be deployed. 20.1, 21.1, or 22.1 are valid values."
  type        = string
  validation {
    condition     = var.avi_version == "20.1" || var.avi_version == "21.1" || var.avi_version == "22.1"
    error_message = "The avi_version value must be one of 20.1, 21.1, or 22.1."
  }
  default = "21.1"
}
variable "avi_upgrade" {
  description = "This variable determines if a patch upgrade is performed after install. The enabled key should be set to true and the url from the Avi Cloud Services portal for the should be set for the upgrade_file_uri key. Valid upgrade_type values are patch or system"
  sensitive   = false
  type        = object({ enabled = bool, upgrade_type = string, upgrade_file_uri = string })
  default     = { enabled = "false", upgrade_type = "patch", upgrade_file_uri = "" }
}
variable "name_prefix" {
  description = "This prefix is appended to the names of the Controller and SEs"
  type        = string
}
variable "controller_ha" {
  description = "If true a HA controller cluster is deployed and configured"
  type        = bool
  default     = "false"
}
variable "register_controller" {
  description = "If enabled is set to true the controller will be registered and licensed with Avi Cloud Services. The Long Organization ID (organization_id) can be found from https://console.cloud.vmware.com/csp/gateway/portal/#/organization/info. The jwt_token can be retrieved at https://portal.avipulse.vmware.com/portal/controller/auth/cspctrllogin"
  sensitive   = false
  type        = object({ enabled = bool, jwt_token = string, email = string, organization_id = string })
  default     = { enabled = "false", jwt_token = "", email = "", organization_id = "" }
}
variable "create_networking" {
  description = "This variable controls the VNET and subnet creation for the AVI Controller. When set to false the custom_controller_resource_group, custom_vnet_name and custom_subnet_name variables must be configured."
  type        = bool
  default     = "true"
}
variable "configure_vnet_peering" {
  description = "This variable is used to peer the created VNET with another VNET"
  type        = object({ enabled = bool, resource_group = string, vnet_name = string, global_peering = bool })
  default     = { enabled = false, resource_group = "", vnet_name = "", global_peering = true }
}
variable "controller_public_address" {
  description = "This variable controls if the Controller has a Public IP Address. When set to false the Ansible provisioner will connect to the private IP of the Controller."
  type        = bool
  default     = "false"
}
variable "vnet_address_space" {
  description = "The CIDR that will be used for creating a VNET for Avi resources"
  type        = string
  default     = "10.255.0.0/16"
}
variable "avi_subnet" {
  description = "The CIDR that will be used for creating a subnet in the Avi VNET"
  type        = string
  default     = "10.255.0.0/24"
}
variable "custom_vnet_name" {
  description = "This field can be used to specify an existing VNET for the controller and SEs. The create_networking variable must also be set to false for this network to be used."
  type        = string
  default     = ""
}
variable "custom_subnet_name" {
  description = "This field can be used to specify a list of existing VNET Subnet for the controller and SEs. The create_networking variable must also be set to false for this network to be used."
  type        = string
  default     = ""
}
variable "create_firewall_rules" {
  description = "This variable controls the Network Security Group (NSG) rule creation for the Avi Controllers. When set to false the necessary firewall rules must be in place before the deployment"
  type        = bool
  default     = "true"
}
variable "create_iam" {
  description = "Create Azure AD Application and Service Principal, Controller Custom Role, and Application Role Binding for Avi Azure Full Access Cloud"
  type        = bool
  default     = "false"
}
variable "controller_default_password" {
  description = "This is the default password for the AVI controller image and can be found in the image download page."
  type        = string
  sensitive   = false
}
variable "controller_password" {
  description = "The password that will be used authenticating with the AVI Controller. This password be a minimum of 8 characters and contain at least one each of uppercase, lowercase, numbers, and special characters"
  type        = string
  sensitive   = false
  validation {
    condition     = length(var.controller_password) > 7
    error_message = "The controller_password value must be more than 8 characters and contain at least one each of uppercase, lowercase, numbers, and special characters."
  }
}
variable "controller_az_app_id" {
  description = "If the create_iam variable is set to false, this is the Azure Application ID that the Avi Controller will use to create Azure resources"
  type        = string
  sensitive   = false
  default     = null
}
variable "controller_az_client_secret" {
  description = "If the create_iam variable is set to false, this is the Azure Client Secret that the Avi Controller will use to create Azure resources"
  type        = string
  sensitive   = false
  default     = null
}
variable "controller_vm_size" {
  description = "The VM size for the AVI Controller"
  type        = string
  default     = "Standard_D8s_v3"
}
variable "se_vm_size" {
  description = "The VM size for the AVI Service Engines. This value can be changed in the Service Engine Group configuration after deployment."
  type        = string
  default     = "Standard_F2s"
}
variable "controller_disk_type" {
  description = "The Type of Storage Account which should back this the Internal OS Disk. Possible values are Premium_LRS, Standard_LRS, StandardSSD_LRS"
  type        = string
  default     = "Premium_LRS"
}
variable "controller_disk_size" {
  description = "The root disk size for the AVI controller"
  type        = number
  default     = 128
  validation {
    condition     = var.controller_disk_size >= 128
    error_message = "The Controller root disk size should be greater than or equal to 128 GB."
  }
}
variable "custom_tags" {
  description = "Custom tags added to Resources created by the module"
  type        = map(string)
  default     = {}
}
variable "configure_controller" {
  description = "Configure the Avi Cloud via Ansible after controller deployment. If not set to true this must be done manually with the desired config"
  type        = bool
  default     = "true"
}
variable "configure_dns_profile" {
  description = "Configure a DNS Profile for DNS Record Creation for Virtual Services. The usable_domains is a list of domains that Avi will be the Authoritative Nameserver for and NS records may need to be created pointing to the Avi Service Engine addresses. Supported profiles for the type parameter are AWS or AVI"
  type = object({
    enabled        = bool,
    type           = optional(string, "AVI"),
    usable_domains = list(string),
    ttl            = optional(string, "30"),
    aws_profile    = optional(object({ iam_assume_role = string, region = string, vpc_id = string, access_key_id = string, secret_access_key = string }))
  })
  default = { enabled = false, type = "AVI", usable_domains = [] }
  validation {
    condition     = contains(["AWS", "AVI"], var.configure_dns_profile.type)
    error_message = "Supported DNS Profile types are 'AWS' or 'AVI'"
  }
}
variable "configure_dns_vs" {
  description = "Create Avi DNS Virtual Service. The subnet_name parameter must be an existing AWS Subnet. If the allocate_public_ip parameter is set to true a EIP will be allocated for the VS. The VS IP address will automatically be allocated via the AWS IPAM"
  type        = object({ enabled = bool, allocate_public_ip = bool })
  default     = { enabled = "false", allocate_public_ip = "false" }
}
variable "configure_gslb" {
  description = "Configures GSLB. In addition the configure_dns_vs variable must also be set for GSLB to be configured. See the GSLB Deployment README section for more information."
  type = object({
    enabled          = bool,
    leader           = optional(bool, false),
    site_name        = string,
    domains          = optional(list(string)),
    create_se_group  = optional(bool, true),
    se_size          = optional(string, "Standard_F2s"),
    additional_sites = optional(list(object({ name = string, ip_address_list = list(string) })))
  })
  default = { enabled = "false", site_name = "", domains = [""] }
}
variable "se_ha_mode" {
  description = "The HA mode of the Service Engine Group. Possible values active/active, n+m, or active/standby"
  type        = string
  default     = "active/active"
  validation {
    condition     = contains(["active/active", "n+m", "active/standby"], var.se_ha_mode)
    error_message = "Acceptable values are active/active, n+m, or active/standby."
  }
}
variable "dns_servers" {
  description = "The optional DNS servers that will be used for local DNS resolution by the controller. The dns_search_domain variable must also be specified if this variable is set. Example [\"8.8.4.4\", \"8.8.8.8\"]"
  type        = list(string)
  default     = null
}
variable "dns_search_domain" {
  description = "The optional DNS search domain that will be used by the controller"
  type        = string
  default     = null
}
variable "ntp_servers" {
  description = "The NTP Servers that the Avi Controllers will use. The server should be a valid IP address (v4 or v6) or a DNS name. Valid options for type are V4, DNS, or V6"
  type        = list(object({ addr = string, type = string }))
  default     = [{ addr = "0.us.pool.ntp.org", type = "DNS" }, { addr = "1.us.pool.ntp.org", type = "DNS" }, { addr = "2.us.pool.ntp.org", type = "DNS" }, { addr = "3.us.pool.ntp.org", type = "DNS" }]
}
variable "email_config" {
  description = "The Email settings that will be used for sending password reset information or for trigged alerts. The default setting will send emails directly from the Avi Controller"
  sensitive   = false
  type        = object({ smtp_type = string, from_email = string, mail_server_name = string, mail_server_port = string, auth_username = string, auth_password = string })
  default     = { smtp_type = "SMTP_LOCAL_HOST", from_email = "admin@avicontroller.net", mail_server_name = "localhost", mail_server_port = "25", auth_username = "", auth_password = "" }
}