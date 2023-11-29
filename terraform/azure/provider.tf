terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.77.0"
    }
  }
#   backend "azurerm" {
#     resource_group_name  = "nader-gs"
#     storage_account_name = "nader3568"
#     container_name       = "tfstate"
#     key                  = "terraform.tfstate"
#   }
}

provider "azurerm" {
  features {}
  skip_provider_registration = true
  alias                      = "cloud"
}