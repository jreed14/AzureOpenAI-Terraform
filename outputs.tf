output "resource_group_name" {
  value = azurerm_resource_group.rg.name
}

output "resource_group_location" {
  value = azurerm_resource_group.rg.location
}


output "public_ip_address" {
  value = azurerm_windows_virtual_machine.main.public_ip_address
}

output "admin_password" {
  sensitive = true
  value     = azurerm_windows_virtual_machine.main.admin_password
}

output "instrumentation_key" {
  value = azurerm_application_insights.appinsights.instrumentation_key
  sensitive = true
}

output "app_id" {
  value = azurerm_application_insights.appinsights.app_id
}

output "bastion_subnet" {
  value = azurerm_subnet.bastion_subnet.id
}

output "endpoint_subnet" {
  value = azurerm_subnet.endpoint.id
}

output "keyvault_id" {
  value = azurerm_key_vault.app-openai-keyvault.id
}

output "prefix" {
  value = "${var.prefix}"  
}

#output "aoai-endpoint-ip" {
#   value = azurerm_private_endpoint.openai-private-endpoint.private_service_connection.private_ip_address
#}