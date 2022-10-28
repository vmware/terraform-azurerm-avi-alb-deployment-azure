# AVI Controller Deployment on Azure Terraform module
This Terraform module creates and configures an AVI (NSX Advanced Load Balancer) Controller on Azure
[![Avi - Single Site Deployment](https://github.com/vmware/terraform-azurerm-avi-alb-deployment-azure/actions/workflows/single-site-test.yml/badge.svg)](https://github.com/vmware/terraform-azurerm-avi-alb-deployment-azure/actions/workflows/single-site-test.yml)
[![Avi - 2 Site GSLB Deployment](https://github.com/vmware/terraform-azurerm-avi-alb-controller-azure/actions/workflows/dual-site-gslb-test.yml/badge.svg)](https://github.com/vmware/terraform-azurerm-avi-alb-deployment-azure/actions/workflows/dual-site-gslb-test.yml)


## Module Functions
The module is meant to be modular and can create all or none of the prerequisite resources needed for the AVI Azure Deployment including:
* VNET and Subnet for the Controller and SEs (configured with create_networking variable)
* VNET Peering (configured with create_vnet_peering and vnet_peering_settings variables)
* Azure Active Directory Application, Service Principal, Custom Role, and Role Assignment for the Controller (configured with create_iam variable)
* Network Security Groups for AVI Controller and SE communication (future work)
* Azure Virtual Machine Instance using an official AVI Azure Marketplace image
* High Availability AVI Controller Deployment (configured with controller_ha variable)

During the creation of the Controller instance the following initialization steps are performed:
* Copy Ansible playbook to controller using the assigned public IP
* Run Ansible playbook to configure initial settings and Azure Full Access Cloud

The Ansible playbook can optionally add these configurations:
* Create Avi DNS Profile (configured with configure_dns_profile and dns_service_domain variables)
* Create Avi DNS Virtual Service (configured with configure_dns_vs and dns_vs_settings variables)
* Configure GSLB (configured with configure_gslb, gslb_site_name, gslb_domains, and configure_gslb_additional_sites variables)

# Environment Requirements

## Azure Prequisites
The following are Azure prerequisites for running this module:
* Subscription created
* Account with either Contributor role (if create_iam is false) or Owner (if create_iam is true)

## Azure Provider
For authenticating to the Azure Provider the instructions found here should be followed - https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs

The azurerm provider block may need to be configured for setting addtional settings depending on the environment. The settings as shown in the example below have been tested sucessfully:

```hcl
provider "azurerm" {
  features {
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
  }
  skip_provider_registration = "true"
}
```
## Avi Controller Image
This module will use the Azure Marketplace for deploying the Avi image. The terms of the image and more information can be found in this link - https://azuremarketplace.microsoft.com/en-us/marketplace/apps/avi-networks.avi-vantage-adc. By default the marketplace agreement is accepted with the create_marketplace_agreement variable. 

## Host OS 
The following packages must be installed on the host operating system:
* curl 

## Usage
This is an example of an HA controller deployment that creates the controller and all other requisite Azure resources.
```hcl
terraform {
  backend "local" {
  }
}
provider "azurerm" {
  features {
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
  }
  skip_provider_registration = "true"
}
module "avi_controller_azure" {
  source  = "vmware/avi-alb-deployment-azure/azurerm"
  version = "1.0.x"

  region                       = "westus2"
  name_prefix                  = "companyname"
  controller_default_password  = "Value Redacted and available within the VMware Customer Portal"
  controller_password          = "<newpassword>"
  create_networking            = true
  create_iam                   = true
  controller_ha                = true
  controller_public_address    = true
  custom_tags                  = { "Role" : "Avi-Controller", "Owner" : "user@email.com", "Department" : "IT" }
  se_ha_mode                   = "active/active"
  vnet_address_space           = "10.255.0.0/16"
  avi_subnet                   = "10.255.0.0/24"
}
output "controller_info" { 
  value = module.avi_controller_azure.controllers
}
```
## GSLB Deployment Example
The example below shows a GSLB deployment with 2 regions utilized. VNET Peering is configured (with create_vnet_peering and vnet_peering_settings variables) between the two newly created Avi VNETs so that the controllers can communicate.
```hcl
terraform {
  backend "local" {
  }
}
module "avi_controller_azure_westus2" {
  source    = "vmware/avi-alb-deployment-azure/azurerm"
  version   = "1.0.x"

  region                       = "westus2"
  name_prefix                  = "companyname"
  controller_default_password  = "Value Redacted and available within the VMware Customer Portal"
  controller_password          = "<newpassword>"
  create_networking            = true
  create_vnet_peering          = true
  vnet_peering_settings        = { global_peering = true, resource_group = "rg-<name_prefix>-avi-<region>", vnet_name = "<name_prefix>-avi-vnet-<region>" }
  create_iam                   = true
  controller_ha                = true
  controller_public_address    = true
  custom_tags                  = { "Role" : "Avi-Controller", "Owner" : "user@email.com", "Department" : "IT" }
  se_ha_mode                   = "active/active"
  vnet_address_space           = "10.251.0.0/16"
  avi_subnet                   = "10.251.0.0/24"
  configure_dns_profile        = "true"
  dns_service_domain           = "west2.avidemo.net"
  configure_dns_vs             = "true"
  create_gslb_se_group        = "true"
  gslb_site_name              = "West2"
}
module "avi_controller_azure_eastus2" {
  source  = "vmware/avi-alb-deployment-azure/azurerm"
  version = "1.0.x"

  region                          = "eastus2"
  name_prefix                     = "companyname"
  controller_default_password     = "Value Redacted and available within the VMware Customer Portal"
  controller_password             = "<newpassword>"
  create_networking               = true
  create_vnet_peering             = true
  vnet_peering_settings           = { global_peering = true, resource_group = "rg-<name_prefix>-avi-<region>", vnet_name = "<name_prefix>-avi-vnet-<region>" }
  create_iam                      = true
  controller_ha                   = true
  controller_public_address       = true
  custom_tags                     = { "Role" : "Avi-Controller", "Owner" : "user@email.com", "Department" : "IT" }
  se_ha_mode                      = "active/active"
  vnet_address_space              = "10.252.0.0/16"
  avi_subnet                      = "10.252.0.0/24"
  configure_dns_profile           = "true"
  dns_service_domain              = "east2.avidemo.net"
  configure_dns_vs                = "true"
  configure_gslb                  = "true"
  gslb_site_name                  = "East2"
  gslb_domains                    = ["gslb.avidemo.net"]
  configure_gslb_additional_sites = "true"
  additional_gslb_sites           = [{name = "West2", ip_address_list = module.avi_controller_azure_westus2.controllers[*].private_ip_address, dns_vs_name = "DNS-VS"}]
}
output "eastus2_controller_info" {
  value = module.avi_controller_azure_eastus2.controllers
}
output "westus2_controller_info" {
  value = module.avi_controller_azure_westus2.controllers
}
```
## Private IP Controller Deployment
For a controller deployment that is only accesible via private IPs the controller_public_address should be set to false to enable this connectivity. In addition it is recommended to either configure VNET peering with the vnet_peering_settings or manually create resource group and VNET/Subnets and specify them with the create-networking = false, custom_controller_resource_group, custom_vnet_name, and custom_subnet_name variables. This is needed so that the controller IPs can be reached by the Ansible provisioner. 

## Day 1 Ansible Configuration and Avi Resource Cleanup
The module copies and runs an Ansible play for configuring the initial day 1 Avi config. The plays listed below can be reviewed by connecting to the Avi Controller by SSH. In an HA setup the first controller will have these files. 

### avi-controller-azure-all-in-one-play.yml
This play will configure the Avi Cloud, Network, IPAM/DNS profiles, DNS Virtual Service, GSLB depending on the variables used. The initial run of this play will output into the ansible-playbook.log file which can be reviewed to determine what tasks were ran. 

Example run (appropriate variable values should be used):
```bash
~$ ansible-playbook avi-controller-azure-all-in-one-play.yml -e password=${var.controller_password} -e azure_app_id=${var.controller_az_app_id} -e azure_auth_token=${var.controller_az_client_secret} -e azure_tenant_id=${data.azurerm_subscription.current.tenant_id} > ansible-playbook-run.log
```

### avi-upgrade.yml
This play will upgrade or patch the Avi Controller and SEs depending on the variables used. When ran this play will output into the ansible-playbook.log file which can be reviewed to determine what tasks were ran. This play can be ran during the initial Terraform deployment with the avi_upgrade variable as shown in the example below:

```hcl
avi_upgrade = { enabled = "true", upgrade_type = "patch", upgrade_file_uri = "URL Copied From portal.avipulse.vmware.com"}
```

An full version upgrade can be done by changing changing the upgrade_type to "system". It is recommended to run this play in a lower environment before running in a production environment and is not recommended for a GSLB setup at this time.

Example run (appropriate variable values should be used):
```bash
~$ ansible-playbook avi-upgrade.yml -e password=${var.controller_password} -e upgrade_type=${var.avi_upgrade.upgrade_type} -e upgrade_file_uri=${var.avi_upgrade.upgrade_file_uri} > ansible-playbook-run.log
```

### avi-cleanup.yml
This play will disable all Virtual Services and delete all existing Avi service engines. This playbook should be ran before deleting the controller with terraform destroy to clean up the resources created by the Avi Controller. 

Example run (appropriate variable values should be used):
```bash
~$ ansible-playbook avi-cleanup.yml -e password=${var.controller_password}
```

## Contributing

The terraform-azurerm-avi-alb-deployment-azure project team welcomes contributions from the community. Before you start working with this project please read and sign our Contributor License Agreement (https://cla.vmware.com/cla/1/preview). If you wish to contribute code and you have not signed our Contributor Licence Agreement (CLA), our bot will prompt you to do so when you open a Pull Request. For any questions about the CLA process, please refer to our [FAQ](https://cla.vmware.com/faq). For more detailed information, refer to [CONTRIBUTING.md](CONTRIBUTING.md).

<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 0.13.6 |
| <a name="requirement_azuread"></a> [azuread](#requirement\_azuread) | ~> 2.26.1 |
| <a name="requirement_azurerm"></a> [azurerm](#requirement\_azurerm) | ~> 3.14.0 |
| <a name="requirement_null"></a> [null](#requirement\_null) | ~> 3.1.1 |
| <a name="requirement_random"></a> [random](#requirement\_random) | ~> 3.3.2 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_azuread"></a> [azuread](#provider\_azuread) | 2.26.1 |
| <a name="provider_azurerm"></a> [azurerm](#provider\_azurerm) | 3.14.0 |
| <a name="provider_null"></a> [null](#provider\_null) | 3.1.1 |
| <a name="provider_random"></a> [random](#provider\_random) | 3.3.2 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [azuread_application.avi](https://registry.terraform.io/providers/hashicorp/azuread/latest/docs/resources/application) | resource |
| [azuread_application_password.avi](https://registry.terraform.io/providers/hashicorp/azuread/latest/docs/resources/application_password) | resource |
| [azuread_service_principal.avi](https://registry.terraform.io/providers/hashicorp/azuread/latest/docs/resources/service_principal) | resource |
| [azurerm_linux_virtual_machine.avi_controller](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/linux_virtual_machine) | resource |
| [azurerm_marketplace_agreement.avi](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/marketplace_agreement) | resource |
| [azurerm_network_interface.avi](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/network_interface) | resource |
| [azurerm_network_interface_security_group_association.controller](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/network_interface_security_group_association) | resource |
| [azurerm_network_security_group.avi_controller_mgmt](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/network_security_group) | resource |
| [azurerm_public_ip.avi](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/public_ip) | resource |
| [azurerm_resource_group.avi](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/resource_group) | resource |
| [azurerm_role_assignment.contributor](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/role_assignment) | resource |
| [azurerm_role_assignment.custom_controller](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/role_assignment) | resource |
| [azurerm_role_definition.custom_controller](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/role_definition) | resource |
| [azurerm_subnet.avi](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/subnet) | resource |
| [azurerm_virtual_network.avi](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/virtual_network) | resource |
| [azurerm_virtual_network_peering.avi](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/virtual_network_peering) | resource |
| [null_resource.ansible_provisioner](https://registry.terraform.io/providers/hashicorp/null/latest/docs/resources/resource) | resource |
| [random_uuid.role_definition](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/uuid) | resource |
| [azuread_client_config.current](https://registry.terraform.io/providers/hashicorp/azuread/latest/docs/data-sources/client_config) | data source |
| [azurerm_resource_group.custom](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/resource_group) | data source |
| [azurerm_subnet.custom](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/subnet) | data source |
| [azurerm_subscription.current](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/subscription) | data source |
| [azurerm_virtual_network.custom](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/virtual_network) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_additional_gslb_sites"></a> [additional\_gslb\_sites](#input\_additional\_gslb\_sites) | The Names and IP addresses of the GSLB Sites that will be configured. If the Site is a controller cluster the ip\_address\_list should have the ip address of each controller. The configure\_gslb\_additional\_sites variable must also be set to true for the sites to be added | `list(object({ name = string, ip_address_list = list(string), dns_vs_name = string }))` | <pre>[<br>  {<br>    "dns_vs_name": "DNS-VS",<br>    "ip_address_list": [<br>      ""<br>    ],<br>    "name": ""<br>  }<br>]</pre> | no |
| <a name="input_avi_subnet"></a> [avi\_subnet](#input\_avi\_subnet) | The CIDR that will be used for creating a subnet in the Avi VNET | `string` | `"10.255.0.0/24"` | no |
| <a name="input_avi_upgrade"></a> [avi\_upgrade](#input\_avi\_upgrade) | This variable determines if a patch upgrade is performed after install. The enabled key should be set to true and the url from the Avi Cloud Services portal for the should be set for the upgrade\_file\_uri key. Valid upgrade\_type values are patch or system | `object({ enabled = bool, upgrade_type = string, upgrade_file_uri = string })` | <pre>{<br>  "enabled": "false",<br>  "upgrade_file_uri": "",<br>  "upgrade_type": "patch"<br>}</pre> | no |
| <a name="input_avi_version"></a> [avi\_version](#input\_avi\_version) | The major and minor version of the AVI Controller version that will be deployed. 20.1, 21.1, or 22.1 are valid values. | `string` | `"21.1"` | no |
| <a name="input_configure_controller"></a> [configure\_controller](#input\_configure\_controller) | Configure the Avi Cloud via Ansible after controller deployment. If not set to true this must be done manually with the desired config | `bool` | `"true"` | no |
| <a name="input_configure_dns_profile"></a> [configure\_dns\_profile](#input\_configure\_dns\_profile) | Configure Avi DNS Profile for DNS Record Creation for Virtual Services. If set to true the dns\_service\_domain variable must also be set | `bool` | `"false"` | no |
| <a name="input_configure_dns_vs"></a> [configure\_dns\_vs](#input\_configure\_dns\_vs) | Create DNS Virtual Service. The configure\_dns\_profile variables must be set to true and their associated configuration variables must also be set | `bool` | `"false"` | no |
| <a name="input_configure_gslb"></a> [configure\_gslb](#input\_configure\_gslb) | Configure GSLB. The gslb\_site\_name, gslb\_domains, and configure\_dns\_vs variables must also be set. Optionally the additional\_gslb\_sites variable can be used to add active GSLB sites | `bool` | `"false"` | no |
| <a name="input_configure_gslb_additional_sites"></a> [configure\_gslb\_additional\_sites](#input\_configure\_gslb\_additional\_sites) | Configure additional GSLB Sites. The additional\_gslb\_sites, gslb\_site\_name, gslb\_domains, and configure\_dns\_vs variables must also be set | `bool` | `"false"` | no |
| <a name="input_controller_az_app_id"></a> [controller\_az\_app\_id](#input\_controller\_az\_app\_id) | If the create\_iam variable is set to false, this is the Azure Application ID that the Avi Controller will use to create Azure resources | `string` | `null` | no |
| <a name="input_controller_az_client_secret"></a> [controller\_az\_client\_secret](#input\_controller\_az\_client\_secret) | If the create\_iam variable is set to false, this is the Azure Client Secret that the Avi Controller will use to create Azure resources | `string` | `null` | no |
| <a name="input_controller_default_password"></a> [controller\_default\_password](#input\_controller\_default\_password) | This is the default password for the AVI controller image and can be found in the image download page. | `string` | n/a | yes |
| <a name="input_controller_disk_size"></a> [controller\_disk\_size](#input\_controller\_disk\_size) | The root disk size for the AVI controller | `number` | `128` | no |
| <a name="input_controller_disk_type"></a> [controller\_disk\_type](#input\_controller\_disk\_type) | The Type of Storage Account which should back this the Internal OS Disk. Possible values are Premium\_LRS, Standard\_LRS, StandardSSD\_LRS | `string` | `"Premium_LRS"` | no |
| <a name="input_controller_ha"></a> [controller\_ha](#input\_controller\_ha) | If true a HA controller cluster is deployed and configured | `bool` | `"false"` | no |
| <a name="input_controller_password"></a> [controller\_password](#input\_controller\_password) | The password that will be used authenticating with the AVI Controller. This password be a minimum of 8 characters and contain at least one each of uppercase, lowercase, numbers, and special characters | `string` | n/a | yes |
| <a name="input_controller_public_address"></a> [controller\_public\_address](#input\_controller\_public\_address) | This variable controls if the Controller has a Public IP Address. When set to false the Ansible provisioner will connect to the private IP of the Controller. | `bool` | `"false"` | no |
| <a name="input_controller_vm_size"></a> [controller\_vm\_size](#input\_controller\_vm\_size) | The VM size for the AVI Controller | `string` | `"Standard_D8s_v3"` | no |
| <a name="input_create_firewall_rules"></a> [create\_firewall\_rules](#input\_create\_firewall\_rules) | This variable controls the Network Security Group (NSG) rule creation for the Avi Controllers. When set to false the necessary firewall rules must be in place before the deployment | `bool` | `"true"` | no |
| <a name="input_create_gslb_se_group"></a> [create\_gslb\_se\_group](#input\_create\_gslb\_se\_group) | Create a SE group for GSLB. This option only applies when configure\_gslb is set to true | `bool` | `"false"` | no |
| <a name="input_create_iam"></a> [create\_iam](#input\_create\_iam) | Create Azure AD Application and Service Principal, Controller Custom Role, and Application Role Binding for Avi Azure Full Access Cloud | `bool` | `"false"` | no |
| <a name="input_create_marketplace_agreement"></a> [create\_marketplace\_agreement](#input\_create\_marketplace\_agreement) | If set to true the user agrees to the terms and conditions for the Avi Marketplace image as found here https://azuremarketplace.microsoft.com/en-us/marketplace/apps/avi-networks.avi-vantage-adc. When multiple instances of this module are used only 1 should have this value set to true to prevent duplicate deployments | `bool` | `"true"` | no |
| <a name="input_create_networking"></a> [create\_networking](#input\_create\_networking) | This variable controls the VNET and subnet creation for the AVI Controller. When set to false the custom\_controller\_resource\_group, custom\_vnet\_name and custom\_subnet\_name variables must be configured. | `bool` | `"true"` | no |
| <a name="input_create_resource_group"></a> [create\_resource\_group](#input\_create\_resource\_group) | If true a Resource Group is created and used for the AVI Controllers and Service Engines | `bool` | `"true"` | no |
| <a name="input_create_vnet_peering"></a> [create\_vnet\_peering](#input\_create\_vnet\_peering) | This variable is used to peer the created VNET. If true the vnet\_peering\_settings variable must be configured | `bool` | `"false"` | no |
| <a name="input_custom_controller_resource_group"></a> [custom\_controller\_resource\_group](#input\_custom\_controller\_resource\_group) | This field can be used to specify an existing Resource Group for AVI Controllers. The create\_resource\_group variable must also be set to false for this resource group to be used. | `string` | `""` | no |
| <a name="input_custom_se_resource_group"></a> [custom\_se\_resource\_group](#input\_custom\_se\_resource\_group) | This field can be used to specify an existing Resource Group for Service Engines. | `string` | `null` | no |
| <a name="input_custom_subnet_name"></a> [custom\_subnet\_name](#input\_custom\_subnet\_name) | This field can be used to specify a list of existing VNET Subnet for the controller and SEs. The create\_networking variable must also be set to false for this network to be used. | `string` | `""` | no |
| <a name="input_custom_tags"></a> [custom\_tags](#input\_custom\_tags) | Custom tags added to Resources created by the module | `map(string)` | `{}` | no |
| <a name="input_custom_vnet_name"></a> [custom\_vnet\_name](#input\_custom\_vnet\_name) | This field can be used to specify an existing VNET for the controller and SEs. The create\_networking variable must also be set to false for this network to be used. | `string` | `""` | no |
| <a name="input_dns_search_domain"></a> [dns\_search\_domain](#input\_dns\_search\_domain) | The optional DNS search domain that will be used by the controller | `string` | `null` | no |
| <a name="input_dns_servers"></a> [dns\_servers](#input\_dns\_servers) | The optional DNS servers that will be used for local DNS resolution by the controller. The dns\_search\_domain variable must also be specified if this variable is set. Example ["8.8.4.4", "8.8.8.8"] | `list(string)` | `null` | no |
| <a name="input_dns_service_domain"></a> [dns\_service\_domain](#input\_dns\_service\_domain) | The DNS Domain that will be available for Virtual Services. Avi will be the Authorative Nameserver for this domain and NS records may need to be created pointing to the Avi Service Engine addresses. An example is demo.Avi.com | `string` | `""` | no |
| <a name="input_dns_vs_allocate_public_ip"></a> [dns\_vs\_allocate\_public\_ip](#input\_dns\_vs\_allocate\_public\_ip) | Defines if a public IP address will be allocated for the DNS VS. Only applies if the configure\_dns\_vs variable is set to true | `bool` | `"true"` | no |
| <a name="input_email_config"></a> [email\_config](#input\_email\_config) | The Email settings that will be used for sending password reset information or for trigged alerts. The default setting will send emails directly from the Avi Controller | `object({ smtp_type = string, from_email = string, mail_server_name = string, mail_server_port = string, auth_username = string, auth_password = string })` | <pre>{<br>  "auth_password": "",<br>  "auth_username": "",<br>  "from_email": "admin@avicontroller.net",<br>  "mail_server_name": "localhost",<br>  "mail_server_port": "25",<br>  "smtp_type": "SMTP_LOCAL_HOST"<br>}</pre> | no |
| <a name="input_gslb_domains"></a> [gslb\_domains](#input\_gslb\_domains) | A list of GSLB domains that will be configured | `list(string)` | <pre>[<br>  ""<br>]</pre> | no |
| <a name="input_gslb_se_size"></a> [gslb\_se\_size](#input\_gslb\_se\_size) | The VM size for the AVI Service Engines used for GSLB. This value can be changed in the Service Engine Group configuration after deployment. | `string` | `"Standard_F2s"` | no |
| <a name="input_gslb_site_name"></a> [gslb\_site\_name](#input\_gslb\_site\_name) | The name of the GSLB site the deployed Controller(s) will be a member of. | `string` | `""` | no |
| <a name="input_name_prefix"></a> [name\_prefix](#input\_name\_prefix) | This prefix is appended to the names of the Controller and SEs | `string` | n/a | yes |
| <a name="input_ntp_servers"></a> [ntp\_servers](#input\_ntp\_servers) | The NTP Servers that the Avi Controllers will use. The server should be a valid IP address (v4 or v6) or a DNS name. Valid options for type are V4, DNS, or V6 | `list(object({ addr = string, type = string }))` | <pre>[<br>  {<br>    "addr": "0.us.pool.ntp.org",<br>    "type": "DNS"<br>  },<br>  {<br>    "addr": "1.us.pool.ntp.org",<br>    "type": "DNS"<br>  },<br>  {<br>    "addr": "2.us.pool.ntp.org",<br>    "type": "DNS"<br>  },<br>  {<br>    "addr": "3.us.pool.ntp.org",<br>    "type": "DNS"<br>  }<br>]</pre> | no |
| <a name="input_region"></a> [region](#input\_region) | The Region that the AVI controller and SEs will be deployed to | `string` | n/a | yes |
| <a name="input_register_controller"></a> [register\_controller](#input\_register\_controller) | If enabled is set to true the controller will be registered and licensed with Avi Cloud Services. The Long Organization ID (organization\_id) can be found from https://console.cloud.vmware.com/csp/gateway/portal/#/organization/info. The jwt\_token can be retrieved at https://portal.avipulse.vmware.com/portal/controller/auth/cspctrllogin | `object({ enabled = bool, jwt_token = string, email = string, organization_id = string })` | <pre>{<br>  "email": "",<br>  "enabled": "false",<br>  "jwt_token": "",<br>  "organization_id": ""<br>}</pre> | no |
| <a name="input_se_ha_mode"></a> [se\_ha\_mode](#input\_se\_ha\_mode) | The HA mode of the Service Engine Group. Possible values active/active, n+m, or active/standby | `string` | `"active/active"` | no |
| <a name="input_se_vm_size"></a> [se\_vm\_size](#input\_se\_vm\_size) | The VM size for the AVI Service Engines. This value can be changed in the Service Engine Group configuration after deployment. | `string` | `"Standard_F2s"` | no |
| <a name="input_use_azure_dns"></a> [use\_azure\_dns](#input\_use\_azure\_dns) | If true the AVI Cloud is configured to use Azure DNS | `bool` | `"false"` | no |
| <a name="input_use_standard_alb"></a> [use\_standard\_alb](#input\_use\_standard\_alb) | If true the AVI Cloud is configured to use standard SKU for the Azure LBs that route to Avi SEs | `bool` | `"false"` | no |
| <a name="input_vnet_address_space"></a> [vnet\_address\_space](#input\_vnet\_address\_space) | The CIDR that will be used for creating a VNET for Avi resources | `string` | `"10.255.0.0/16"` | no |
| <a name="input_vnet_peering_settings"></a> [vnet\_peering\_settings](#input\_vnet\_peering\_settings) | This variable is used to peer the created VNET. If true the vnet\_peering\_settings variable must be configured | `object({ resource_group = string, vnet_name = string, global_peering = bool })` | `null` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_controller_private_addresses"></a> [controller\_private\_addresses](#output\_controller\_private\_addresses) | The Private IP Addresses allocated for the Avi Controller(s) |
| <a name="output_controller_resource_group"></a> [controller\_resource\_group](#output\_controller\_resource\_group) | The Resource Group used for the Avi Controller |
| <a name="output_controller_vnet"></a> [controller\_vnet](#output\_controller\_vnet) | The VNET that the Avi Controller is deployed to |
| <a name="output_controllers"></a> [controllers](#output\_controllers) | The AVI Controller(s) Information |
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
