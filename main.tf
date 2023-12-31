resource "azurerm_resource_group" "rg" {
  location = "eastus"
  name     = "openai-rg-terraform"
}

resource "azurerm_virtual_network" "ai_workloads_vnet" {
  name                         = "azure_openai_network"
  address_space                = ["10.0.0.0/16"]
  location                     = azurerm_resource_group.rg.location
  resource_group_name          = azurerm_resource_group.rg.name

}

resource "azurerm_network_security_group" "basicnsg" {
  name                = "${var.prefix}-basicnsg"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

}


resource "azurerm_subnet" "endpoint" {
 name                 = "endpoint"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.ai_workloads_vnet.name
  address_prefixes     = ["10.0.2.0/24"]

  private_link_service_network_policies_enabled = true
}


resource "azurerm_subnet" "bastion_subnet" {
name                   = "AzureBastionSubnet"
resource_group_name    = azurerm_resource_group.rg.name
virtual_network_name = azurerm_virtual_network.ai_workloads_vnet.name

address_prefixes     = ["10.0.3.0/24"]

  private_link_service_network_policies_enabled = true

}

resource "azurerm_subnet" "APIManagementSubnet" {
name                   = "APIManagementSubnet"
resource_group_name    = azurerm_resource_group.rg.name
virtual_network_name   = azurerm_virtual_network.ai_workloads_vnet.name

address_prefixes       = ["10.0.4.0/24"]

  private_link_service_network_policies_enabled = true

}

resource "azurerm_subnet" "computesubnet" {
name                   = "compute"
resource_group_name    = azurerm_resource_group.rg.name
virtual_network_name = azurerm_virtual_network.ai_workloads_vnet.name

address_prefixes     = ["10.0.5.0/24"]

  private_link_service_network_policies_enabled = true

}

resource "azurerm_subnet_network_security_group_association" "basicnsg-to-computesubnet" {
  subnet_id                 = azurerm_subnet.computesubnet.id
  network_security_group_id = azurerm_network_security_group.basicnsg.id
}


resource "azurerm_subnet_network_security_group_association" "basicnsg-to-endpointsubnet" {
  subnet_id                 = azurerm_subnet.endpoint.id
  network_security_group_id = azurerm_network_security_group.basicnsg.id
}

resource "azurerm_subnet_network_security_group_association" "basicnsg-to-apimsubnet" {
  subnet_id                 = azurerm_subnet.APIManagementSubnet.id
  network_security_group_id = azurerm_network_security_group.basicnsg.id
}


 resource "azurerm_private_dns_zone" "private_zone_ai_vnet" {
  name                 = "privatelink.openai.azure.com"
  resource_group_name  = azurerm_resource_group.rg.name
  
 }

#resource "azurerm_private_dns_a_record" "aoai-dns-pvt-link" {
#  name                 = "aoai-pvt-link"
#  zone_name            = join (".", [azurerm_cognitive_account.openai.custom_subdomain_name, azurerm_private_dns_zone.private_zone_ai_vnet.name]) 
#  ttl                  = 300
#  records              =  azurerm_private_endpoint.openai-private-endpoint.private_ip_address
#
# depends_on = [
#   azurerm_private_dns_zone.private_zone_ai_vnet,
#   azurerm_private_endpoint.openai-private-endpoint
#]
#}

resource "azurerm_private_dns_zone_virtual_network_link" "vnet_link_to_AI-vnet" {
  name                  = "virtual-network-dns-link"
  resource_group_name   = azurerm_resource_group.rg.name
  private_dns_zone_name = azurerm_private_dns_zone.private_zone_ai_vnet.name
  virtual_network_id    = azurerm_virtual_network.ai_workloads_vnet.id
  registration_enabled = true
}

resource "azurerm_bastion_host" "bastion_host" {
  name                = "azurebastion"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                 = "configuration"
    subnet_id            = azurerm_subnet.bastion_subnet.id
    public_ip_address_id = azurerm_public_ip.bastion_pub_ip.id
  }
   depends_on = [
        azurerm_virtual_network.ai_workloads_vnet,
        azurerm_subnet.bastion_subnet,
    
  ]

}

resource "azurerm_public_ip" "bastion_pub_ip" {
  name                = "bastion_pubip"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
}





resource "azurerm_windows_virtual_machine" "main" {
  name                  = "${var.prefix}-vm"
  location              = azurerm_resource_group.rg.location
  resource_group_name   = azurerm_resource_group.rg.name
  network_interface_ids = [azurerm_network_interface.main.id]
  size                  = "Standard_DS1_v2"
  admin_username        = "adminuser"
  admin_password        = random_password.password.result
  
  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2022-datacenter-azure-edition"
    version   = "latest"
  }
 
  os_disk {
    name                 = "${var.prefix}-vmOsDisk"
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

}

resource "random_password" "password" {
  length      = 20
  min_lower   = 1
  min_upper   = 1
  min_numeric = 1
  min_special = 1
  special     = true
}


resource "azurerm_network_interface" "main" {
  name                = "${var.prefix}-nic"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "testconfiguration1"
    subnet_id                     = azurerm_subnet.computesubnet.id
    private_ip_address_allocation = "Dynamic"
  }
}



resource "azurerm_cognitive_account" "openai" {
  custom_subdomain_name         = "${var.prefix}-openai"
  kind                          = "OpenAI"
  location                      = "eastus"
  name                          = "${var.prefix}-openai"
  public_network_access_enabled = false
  resource_group_name           = azurerm_resource_group.rg.name
  sku_name                      = "S0"
  depends_on = [
    azurerm_resource_group.rg,
  ]
}

resource "azurerm_cognitive_deployment" "openaideployment" {
  name                 = "example-cd"
  cognitive_account_id = azurerm_cognitive_account.openai.id
  model {
    format  = "OpenAI"
    name    = "text-curie-001"
    version = "1"
  }

  scale {
    type = "Standard"
  }
}

resource "azurerm_key_vault" "app-openai-keyvault" {
  enable_rbac_authorization       = true
  enabled_for_deployment          = true
  enabled_for_disk_encryption     = true
  enabled_for_template_deployment = true
  location                        = "eastus"
  name                            = "${var.prefix}-openai-keyvault"
  resource_group_name             =  azurerm_resource_group.rg.name
  sku_name                        = "standard"
  tenant_id                       = data.azurerm_client_config.current.tenant_id
  depends_on = [
    azurerm_resource_group.rg,
  ]


  
}

resource "azurerm_role_assignment" "keyvault_access" {
  scope                      = azurerm_key_vault.app-openai-keyvault.id
  role_definition_name       = "Key Vault Administrator"
  principal_id               = data.azurerm_client_config.current.object_id

  depends_on = [
    azurerm_key_vault.app-openai-keyvault,
  ]
}



resource "azurerm_key_vault_secret" "vmpw" {
  name         = "adminpw"
  value        = random_password.password.result
  key_vault_id = azurerm_key_vault.app-openai-keyvault.id

  depends_on = [
    azurerm_role_assignment.keyvault_access,
  ]
}

resource "azurerm_private_dns_zone" "vault_dns_zone" {
  name                          = "privatelink.vaultcore.azure.net"
  resource_group_name           = azurerm_resource_group.rg.name
}


resource "azurerm_private_endpoint" "keyvault-private-endpoint" {
   custom_network_interface_name = "keyvault-pvtendpoint-nic"
   location                      = azurerm_resource_group.rg.location
   name                          = "keyvault-pvtendpoint"
   resource_group_name           = azurerm_resource_group.rg.name
   subnet_id                     = azurerm_subnet.endpoint.id
   
   
   private_service_connection {
     is_manual_connection           = false
     name                           = "keyvault-pvtendpoint"
     private_connection_resource_id = azurerm_key_vault.app-openai-keyvault.id
     subresource_names              = ["Vault"]
    }

  private_dns_zone_group {
    name                          = "vaultdnszonegroup"
    private_dns_zone_ids          = [azurerm_private_dns_zone.vault_dns_zone.id]
  }

  depends_on = [
    azurerm_key_vault.app-openai-keyvault, 
    azurerm_virtual_network.ai_workloads_vnet,
    azurerm_subnet.endpoint,
    azurerm_key_vault_secret.vmpw,
    azurerm_role_assignment.keyvault_access,
    azurerm_private_dns_zone.vault_dns_zone
  ]
}

resource "azurerm_private_dns_zone_virtual_network_link" "vnet_link_to_vault" {
  name                  = "virtual-network-dns-link_vault"
  resource_group_name   = azurerm_resource_group.rg.name
  private_dns_zone_name = azurerm_private_dns_zone.vault_dns_zone.name
  virtual_network_id    = azurerm_virtual_network.ai_workloads_vnet.id

depends_on = [
  azurerm_private_dns_zone.vault_dns_zone
]

}

resource "random_id" "random_id" {
  keepers = {
    # Generate a new ID only when a new resource group is defined
    resource_group = azurerm_resource_group.rg.name
  }

  byte_length = 8
}

resource "azurerm_api_management" "apim" {
  name                = "${var.prefix}-apim-${random_id.random_id.hex}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  publisher_name      = "Contoso"
  publisher_email     = "john.doe@contoso.com"

  sku_name = "Developer_1"
}



resource "azurerm_private_endpoint" "openai-private-endpoint" {
  custom_network_interface_name = "openai-pvtendpoint-nic"
  location                      =  azurerm_resource_group.rg.location
  name                          = "openai-pvtendpoint"
  resource_group_name           = azurerm_resource_group.rg.name
  subnet_id                     = azurerm_subnet.endpoint.id
  
  private_service_connection {
    is_manual_connection           = false
    name                           = "openai-pvtendpoint"
    private_connection_resource_id = azurerm_cognitive_account.openai.id
    subresource_names              = ["account"]
  }

private_dns_zone_group {
    name                          = "openaidnszonegroup"
    private_dns_zone_ids          = [azurerm_private_dns_zone.private_zone_ai_vnet.id]
  }

  depends_on = [
    azurerm_cognitive_account.openai,
  ]
}

resource "azurerm_log_analytics_workspace" "la-workspace" {
  name                = "la-worskpace"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  sku                 = "PerGB2018"
  retention_in_days   = 30
}

resource "azurerm_application_insights" "appinsights" {
  name                = "apim-test-appinsights"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  application_type    = "web"
}





