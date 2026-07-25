# This module is a modified copy of vendor/mc-vm-csp/azure that accepts
# an external provider configuration instead of configuring its own.
# This allows the module to be used with count/for_each.

terraform {
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
    }
  }
}

# NOTE: No provider "azurerm" {} block here - provider must be passed by caller
