terraform {
  required_version = ">= 0.12"
}

provider "azurerm" {
  features {
  }
  skip_provider_registration = true
}

variable "username" {
}

variable "password" {
}

variable "event_hub_name" {
}

variable "resource_group" {
}

variable "name_space_name" {
}

resource "azurerm_resource_group" "some_resource_group" {
  name     = var.resource_group
  location = "East US"
}

resource "azurerm_eventhub_namespace" "some_namespace" {
  name                = var.name_space_name
  location            = azurerm_resource_group.some_resource_group.location
  resource_group_name = azurerm_resource_group.some_resource_group.name
  sku                 = "Standard"
}

resource "azurerm_eventhub" "some_eventhub" {
  name                = var.event_hub_name
  namespace_name      = azurerm_eventhub_namespace.some_namespace.name
  resource_group_name = azurerm_resource_group.some_resource_group.name
  message_retention   = 1
  partition_count     = 2
}

