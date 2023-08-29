resource "azurerm_private_endpoint" "keyvault-private-endpoint" {
   custom_network_interface_name = "keyvault-pvtendpoint-nic"
   location                      = module.core.resource_group_locationn
   name                          = "keyvault-pvtendpoint"
   resource_group_name           = module.core.resource_group_name
   subnet_id                     = module.core.endpoint_subnet
   private_service_connection {
     is_manual_connection           = false
     name                           = "keyvault-pvtendpoint"
     private_connection_resource_id = module.core.keyvault_id
  }
  depends_on = [
    module.core
    
  ]
}