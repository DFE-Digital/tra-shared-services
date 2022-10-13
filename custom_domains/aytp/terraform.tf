terraform {

  required_version = "= 1.2.7"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "3.26.0"
    }
  }
  backend "azurerm" {
  }
}

provider "azurerm" {
  features {}

  skip_provider_registration = true
}

provider "azurerm" {
  features {}
  version         = "3.26.0"
  alias           = "app_subcription"
  subscription_id = var.app_sub_id
}
