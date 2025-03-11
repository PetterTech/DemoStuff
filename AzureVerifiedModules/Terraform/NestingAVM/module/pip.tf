variable "name" {
  description = "The name of the public IP address."
}
variable "location" {
  description = "The location/region where the public IP address will be created."
}
variable "resource_group_name" {
  description = "The name of the resource group in which to create the public IP address."
}

module "avm-res-network-publicipaddress" {
  source  = "Azure/avm-res-network-publicipaddress/azurerm"
  version = "0.2.0"
  location = var.location
  resource_group_name = var.resource_group_name
  name = var.name
  ddos_protection_mode = "Enabled"
}