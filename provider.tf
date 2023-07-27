provider "azurerm" {
  features {
  }
}

data "azurerm_client_config" "current" {
}

output "tenant_id" {
  value = data.azurerm_client_config.current.tenant_id
}