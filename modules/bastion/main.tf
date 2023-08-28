resource "azurerm_bastion_host" "bastion_host" {
  name                = "azurebastion"
  location            = module.core.resource_group_location
  resource_group_name = module.core.resource_group_name

  ip_configuration {
    name                 = "configuration"
    subnet_id            = module.core.bastion_subnet
    public_ip_address_id = azurerm_public_ip.bastion_pub_ip.id
  }
   depends_on = [
        azurerm_public_ip.bastion_pub_ip,
  ]

}

resource "azurerm_public_ip" "bastion_pub_ip" {
  name                = "bastion_pubip"
  location            = module.core.resource_group_location
  resource_group_name = module.core.resource_group_name
  allocation_method   = "Static"
  sku                 = "Standard"
}
