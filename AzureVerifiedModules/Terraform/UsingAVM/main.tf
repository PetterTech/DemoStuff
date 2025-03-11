variable "subscription_id" {
  description = "The Azure subscription ID."
}

provider "azurerm" {
  features {}
  subscription_id = var.subscription_id
}

module "avm-res-network-publicipaddress" {
  source  = "Azure/avm-res-network-publicipaddress/azurerm"
  version = "0.2.0"
  location = "swedencentral"
  resource_group_name = "TerraformDemo-rg"
  name = "myavmpublicip-pip"
}