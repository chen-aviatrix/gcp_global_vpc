provider "azurerm" {
  environment     = var.environment[var.azure_environment]
  subscription_id = var.arm_subscription_id
  tenant_id       = var.arm_tenant_id
  client_id       = var.arm_client_id
  client_secret   = var.arm_client_secret
  features {
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
  }
}
