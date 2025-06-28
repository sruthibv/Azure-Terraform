/*
terraform {
  backend "azurerm" {
    resource_group_name   = "veera-rg"         # Resource group where the backend storage is created
    storage_account_name  = "storageveera"  # Must be globally unique across Azure
    container_name        = "tfstate"            # Blob container for storing the state file
    key                   = "infra/terraform.tfstate"  # Path to the state file inside the container
  }
}
*/
