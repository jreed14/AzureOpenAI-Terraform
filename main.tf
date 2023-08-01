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

resource "azurerm_subnet" "service" {
 name                 = "service"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.ai_workloads_vnet.name
  address_prefixes     = ["10.0.1.0/24"]

  enforce_private_link_service_network_policies = true
}

resource "azurerm_subnet" "endpoint" {
  name                 = "service"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.ai_workloads_vnet.name
  address_prefixes     = ["10.0.2.0/24"]

  enforce_private_link_service_network_policies = true
}

resource "azurerm_subnet" "bastion_subnet" {
name                   = "AzureBastionSubnet"
resource_group_name    = azurerm_resource_group.rg.name
virtual_network_name = azurerm_virtual_network.ai_workloads_vnet.name

address_prefixes     = ["10.0.3.0/24"]

  enforce_private_link_service_network_policies = true

}

resource "azurerm_subnet" "APIManagementSubnet" {
name                   = "APIManagementSubnet"
resource_group_name    = azurerm_resource_group.rg.name
virtual_network_name = azurerm_virtual_network.ai_workloads_vnet.name

address_prefixes     = ["10.0.4.0/24"]

  enforce_private_link_service_network_policies = true

}

resource "azurerm_subnet" "computesubnet" {
name                   = "compute"
resource_group_name    = azurerm_resource_group.rg.name
virtual_network_name = azurerm_virtual_network.ai_workloads_vnet.name

address_prefixes     = ["10.0.5.0/24"]

  enforce_private_link_service_network_policies = true

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

resource "azurerm_bastion_host" "bastion_host" {
  name                = "azurebastion"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                 = "configuration"
    subnet_id            = azurerm_subnet.bastion_subnet.id
    public_ip_address_id = azurerm_public_ip.bastion_pub_ip.id
  }
}

resource "azurerm_public_ip" "bastion_pub_ip" {
  name                = "bastion_pubip"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
}


resource "azurerm_cognitive_account" "openai" {
  custom_subdomain_name         = "openai-tf-build"
  kind                          = "OpenAI"
  location                      = "eastus"
  name                          = "openai-tf-build"
  public_network_access_enabled = false
  resource_group_name           = azurerm_resource_group.rg.name
  sku_name                      = "S0"
  depends_on = [
    azurerm_resource_group.rg,
  ]
}
resource "azurerm_cognitive_deployment" "gpt-35-deployment" {
  cognitive_account_id =  azurerm_cognitive_account.openai.id
  name                 = "test-chat-model"
  rai_policy_name      = "Microsoft.Default"

  model {
    format  = "OpenAI"
    name    = "gpt-35-turbo"
    version = "0301"
  }
  scale {
    type = "Standard"
  }
  depends_on = [
    azurerm_cognitive_account.openai,
  ]
}
resource "azurerm_cognitive_deployment" "code-davinci-deployment" {
  cognitive_account_id =  azurerm_cognitive_account.openai.id
  name                 = "test-deployment-model"
  model {
    format  = "OpenAI"
    name    = "code-davinci-002"
    version = "1"
  }
scale {
    type = "Standard"
  }
  depends_on = [
    azurerm_cognitive_account.openai,
  ]
}
resource "azurerm_key_vault" "app-openai-keyvault" {
  enable_rbac_authorization       = true
  enabled_for_deployment          = true
  enabled_for_disk_encryption     = true
  enabled_for_template_deployment = true
  location                        = "eastus"
  name                            = "jrdev-tf-openai-keyvault"
  resource_group_name             =  azurerm_resource_group.rg.name
  sku_name                        = "standard"
  tenant_id                       = data.azurerm_client_config.current.tenant_id
  depends_on = [
    azurerm_resource_group.rg,
  ]


// resource "azurerm_private_dns_zone" "private_zone_ai_vnet" {
//  name                = "privatelink.blob.core.windows.net"
//  resource_group_name = azurerm_resource_group.example.name

// }

//resource "azurerm_private_dns_zone_virtual_network_link" "vnet_link_to_AI-vnet" {
//  name                  = "virtual-network-dns-link"
//  resource_group_name   = azurerm_resource_group.rg.name
//  private_dns_zone_name = azurerm_private_dns_zone.private_zone_ai_vnet.name
//  virtual_network_id    = azurerm_virtual_network.ai_workloads_vnet.id
//}

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
  publisher_name      = "${var.publisher_name}"
  publisher_email     = "${var.publisher_email}"

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
  depends_on = [
    azurerm_cognitive_account.openai,
  ]
}

