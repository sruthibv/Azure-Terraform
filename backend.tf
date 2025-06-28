//terraform {
  backend "azurerm" {
    resource_group_name   = "tfstate-rg"         # Change to your backend RG
    storage_account_name  = "tfstateaccount123"  # Must be globally unique
    container_name        = "tfstate"            # Blob container name
    key                   = "infra/terraform.tfstate"
  }
}//
