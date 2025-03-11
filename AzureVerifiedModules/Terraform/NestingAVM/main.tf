variable "subscription_id" {
  description = "The Azure subscription ID."
}

provider "azurerm" {
  features {}
  subscription_id = var.subscription_id
}

module "nested" {
  source = "./module"
  location = "swedencentral"
  resource_group_name = "TerraformDemo-rg"
  name = "mynestedpublicip-pip"
}