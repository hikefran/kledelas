terraform {
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
    }
  }

#   backend "azurerm" {
#     resource_group_name  = "iac"
#     storage_account_name = "terraformstatebvw"
#     container_name       = "terraformstatebrunowolff"
#     key                  = "terraform.tfstate"
#   }
 }

provider "azurerm" {
  features {}
  use_msi = true
}