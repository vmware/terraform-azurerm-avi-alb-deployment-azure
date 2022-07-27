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
  description = "The major and minor version of the AVI Controller version that will be deployed. 18.2, 20.1, or 21.1 are valid values."
  type        = string
  validation {
    condition     = var.avi_version == "18.2" || var.avi_version == "20.1" || var.avi_version == "21.1"
    error_message = "The avi_version value must be one of 18.2, 20.1, or 21.1."
  }
  default = "20.1"
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
variable "create_networking" {
  description = "This variable controls the VNET and subnet creation for the AVI Controller. When set to false the custom_controller_resource_group, custom_vnet_name and custom_subnet_name variables must be configured."
  type        = bool
  default     = "true"
}
variable "create_vnet_peering" {
  description = "This variable is used to peer the created VNET. If true the vnet_peering_settings variable must be configured"
  type        = bool
  default     = "false"
}
variable "vnet_peering_settings" {
  description = "This variable is used to peer the created VNET. If true the vnet_peering_settings variable must be configured"
  type        = object({ resource_group = string, vnet_name = string, global_peering = bool })
  default     = null
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
  sensitive   = true
}
variable "controller_password" {
  description = "The password that will be used authenticating with the AVI Controller. This password be a minimum of 8 characters and contain at least one each of uppercase, lowercase, numbers, and special characters"
  type        = string
  sensitive   = true
  validation {
    condition     = length(var.controller_password) > 7
    error_message = "The controller_password value must be more than 8 characters and contain at least one each of uppercase, lowercase, numbers, and special characters."
  }
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
variable "configure_cloud" {
  description = "Configure the Avi Cloud via Ansible after controller deployment. If not set to true this must be done manually with the desired config"
  type        = bool
  default     = "true"
}
variable "configure_dns_profile" {
  description = "Configure Avi DNS Profile for DNS Record Creation for Virtual Services. If set to true the dns_service_domain variable must also be set"
  type        = bool
  default     = "false"
}
variable "dns_service_domain" {
  description = "The DNS Domain that will be available for Virtual Services. Avi will be the Authorative Nameserver for this domain and NS records may need to be created pointing to the Avi Service Engine addresses. An example is demo.Avi.com"
  type        = string
  default     = ""
}
variable "configure_dns_vs" {
  description = "Create DNS Virtual Service. The configure_dns_profile variables must be set to true and their associated configuration variables must also be set"
  type        = bool
  default     = "false"
}
variable "dns_vs_allocate_public_ip" {
  description = "Defines if a public IP address will be allocated for the DNS VS. Only applies if the configure_dns_vs variable is set to true"
  type        = bool
  default     = "true"
}
variable "configure_gslb" {
  description = "Configure GSLB. The gslb_site_name, gslb_domains, and configure_dns_vs variables must also be set. Optionally the additional_gslb_sites variable can be used to add active GSLB sites"
  type        = bool
  default     = "false"
}
variable "gslb_site_name" {
  description = "The name of the GSLB site the deployed Controller(s) will be a member of."
  type        = string
  default     = ""
}
variable "gslb_domains" {
  description = "A list of GSLB domains that will be configured"
  type        = list(string)
  default     = [""]
}
variable "configure_gslb_additional_sites" {
  description = "Configure Additional GSLB Sites. The additional_gslb_sites, gslb_site_name, gslb_domains, and configure_dns_vs variables must also be set. Optionally the additional_gslb_sites variable can be used to add active GSLB sites"
  type        = bool
  default     = "false"
}
variable "additional_gslb_sites" {
  description = "The Names and IP addresses of the GSLB Sites that will be configured. If the Site is a controller cluster the ip_address_list should have the ip address of each controller."
  type        = list(object({ name = string, ip_address_list = list(string), dns_vs_name = string }))
  default     = [{ name = "", ip_address_list = [""], dns_vs_name = "DNS-VS" }]
}
variable "create_gslb_se_group" {
  description = "Create a SE group for GSLB. This option only applies when configure_gslb is set to true"
  type        = bool
  default     = "true"
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
  sensitive   = true
  type        = object({ smtp_type = string, from_email = string, mail_server_name = string, mail_server_port = string, auth_username = string, auth_password = string })
  default     = { smtp_type = "SMTP_LOCAL_HOST", from_email = "admin@avicontroller.net", mail_server_name = "localhost", mail_server_port = "25", auth_username = "", auth_password = "" }
}
