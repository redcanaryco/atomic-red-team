terraform {
  required_version = ">= 0.12"
}

provider "azurerm" {
  features {
  }
}

resource "azurerm_resource_group" "some_resource_group" {
  name     = "atomicredteam-rg"
  location = "West Europe"
}

resource "azurerm_eventhub_namespace" "some_namespace" {
  name                = "atomicredteam-ns"
  location            = azurerm_resource_group.some_resource_group.location
  resource_group_name = azurerm_resource_group.some_resource_group.name
  sku                 = "standard"
}

resource "azurerm_eventhub" "some_eventhub" {
  name                = "atomicredteam-eventhub"
  namespace_name      = azurerm_eventhub_namespace.some_namespace.name
  resource_group_name = azurerm_resource_group.some_resource_group.name
  message_retention   = 1
  partition_count     = 2
}

