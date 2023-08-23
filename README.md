# AzureOpenAI-Terraform

This Github repository provides a quick start template to deploy receommended infrastructure to securly deploy the Azure Open AI Service. The deployment method utilizes Terraform templates. 

## Prerequisites 
* [Azure Subscription](https://azure.microsoft.com/en-us/get-started/)
* [Terraform](https://learn.microsoft.com/en-us/azure/developer/terraform/quickstart-configure) 
* [Azure Open AI Access](https://customervoice.microsoft.com/Pages/ResponsePage.aspx?id=v4j5cvGGr0GRqy180BHbR7en2Ais5pxKtso_Pz4b1_xUOFA5Qk1UWDRBMjg0WFhPMkIzTzhKQ1dWNyQlQCN0PWcu)
  

## Getting Started

To deploy the Azure Open AI recommended infrastructure via Terraform:
1. Clone this Repo
2. Navigate to the folder and initalize terraform `terraform init`
3. Run `terraform apply` to view infrastructure that will be deployed
4. Add variables
    - Prefix - usually 3-5 characters that will be appended to all resources. Follow your organizations naming convention 
5. Review created infrastructure 
6. Type yes to start the build
    
## Infrastucture deployed    

* Virtual Network
    * Bastion Subnet
    * API Management Subnet
    * Compute Subnet 
    * Private Endpoints Subnet
* Private DNS Zone
* Azure Open AI Instance
    * Private endpoint enabled
* Azure Bastion Service
* Virtual Machine 
* Key Vault
* API Management

![alt text]()

## Post Deployment Steps
* Add Azure Open AI Definition to API Management
* Add Logger for app insights