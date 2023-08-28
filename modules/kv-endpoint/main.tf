resource "azurerm_private_endpoint" "keyvault-private-endpoint" {
  custom_network_interface_name = "keyvault-pvtendpoint-nic"
  location                      =  azurerm_resource_group.rg.location
 name                          = "keyvault-pvtendpoint"
 resource_group_name           = azurerm_resource_group.rg.name
  subnet_id                     = azurerm_subnet.endpoint.id
  private_service_connection {
    is_manual_connection           = false
    name                           = "keyvault-pvtendpoint"
    private_connection_resource_id = azurerm_key_vault.app-openai-keyvault.id
  }
  depends_on = [
    azurerm_key_vault.app-openai-keyvault,
  ]
}