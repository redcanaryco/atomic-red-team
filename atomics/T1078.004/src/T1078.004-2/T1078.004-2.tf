terraform {
  required_version = ">= 0.12"
}

provider "azurerm" {
  features {
  }
  skip_provider_registration = true
}

variable "resource_group" {
}

variable "runbook_name" {
}

variable "automation_account_name" {
}

resource "azurerm_resource_group" "rg" {
  name     = var.resource_group
  location = "East US"
}

resource "azurerm_automation_account" "account" {
  name                = var.automation_account_name
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  sku_name = "Basic"
}