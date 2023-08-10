provider "azurerm" {
  features {
    key_vault {
    purge_soft_deleted_secrets_on_destroy = true
  }
}
}
data "azurerm_client_config" "current" {
}

output "tenant_id" {
  value = data.azurerm_client_config.current.tenant_id
}

output "object_id" {
  value = data.azurerm_client_config.current.object_id
}