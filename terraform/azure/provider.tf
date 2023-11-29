terraform {
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
    }
  }

  backend "azurerm" {
    resource_group_name  = "VAIPALEMEIRAS"
    storage_account_name = "deyvinss"
    container_name       = "tfstate"
    key                  = "terraform.tfstate"
  }
 }

provider "azurerm" {
  features {}
  use_msi = true
}