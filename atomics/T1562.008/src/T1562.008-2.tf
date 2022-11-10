terraform {
  required_version = ">= 0.12"
}

provider "azurerm" {
  features {
  }
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
  name     = "atomicredteam-rg"
  location = "West Europe"
}

resource "azurerm_eventhub_namespace" "some_namespace" {
  name                = "atomicredteam-ns"
  location            = azurerm_resource_group.some_resource_group.location
  resource_group_name = azurerm_resource_group.some_resource_group.name
  sku                 = "Standard"
}

resource "azurerm_eventhub" "some_eventhub" {
  name                = "atomicredteam-eventhub"
  namespace_name      = azurerm_eventhub_namespace.some_namespace.name
  resource_group_name = azurerm_resource_group.some_resource_group.name
  message_retention   = 1
  partition_count     = 2
}

