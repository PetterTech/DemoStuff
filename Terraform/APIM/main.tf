# Configure the Azure provider
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0.2"
    }
  }

  required_version = ">= 1.1.0"
}

provider "azurerm" {
  features {}
}

# Resource group
resource "azurerm_resource_group" "rg" {
  name     = "rg-terraformPlayground"
  location = "swedencentral"
}

# vNet
resource "azurerm_virtual_network" "vnet" {
  name                = "vnet-terraformPlayground"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  address_space       = ["10.13.32.0/22"]
}

# Bastion subnet
resource "azurerm_subnet" "bastion" {
  name                 = "AzureBastionSubnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.13.32.0/24"]
}

# VM subnet
resource "azurerm_subnet" "vm" {
  name                 = "subnet-VM"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.13.33.0/24"]
}

# APIM subnet
resource "azurerm_subnet" "apim" {
  name                 = "subnet-APIM"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.13.34.0/24"]
}

# Management VM
resource "azurerm_network_interface" "managementvmnic" {
    name                      = "nic-managementvm"
    resource_group_name       = azurerm_resource_group.rg.name
    location                  = azurerm_resource_group.rg.location
    ip_configuration {
        name                          = "ipconfig-terraformPlayground"
        subnet_id                     = azurerm_subnet.vm.id
        private_ip_address_allocation = "Dynamic"
    }
}
resource "azurerm_windows_virtual_machine" "managementvm" {
  name                  = "managementvm"
  resource_group_name   = azurerm_resource_group.rg.name
  location              = azurerm_resource_group.rg.location
  size                  = "Standard_Da2ds_v5"
  admin_username        = "adminuser"
  admin_password        = "Password1234!"
  network_interface_ids = [azurerm_network_interface.nic.id]
  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }
  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2019-Datacenter"
    version   = "latest"
  }
}

# APIM public IP
resource "azurerm_public_ip" "apim" {
  name                = "pip-apimPublicIP"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  allocation_method   = "Static"
  sku                 = "Standard"
}

# API Management
resource "azurerm_api_management" "apim" {
  name                = "apim-terraformPlayground"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  sku_name            = "Developer_1"
  publisher_name      = "Terraform Playground"
  publisher_email     = "none@yourbusiness.com"
  virtual_network_type = "Internal"
    virtual_network_configuration {
        subnet_id = azurerm_subnet.apim.id
    }
  public_ip_address_id = azurerm_public_ip.apim.id
}
