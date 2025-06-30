provider "azurerm" {
  features {}
  subscription_id = "0af586a9-cfb7-45ea-b395-c53780f7659d" #give our subcription of azure 
}
resource "azurerm_resource_group" "rg" {
  name     = "veera-rg"
  location = "East US"
}

resource "azurerm_storage_account" "storage" {
  name                     = "storageveeranaruto" # must be globally unique
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = azurerm_resource_group.rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

resource "azurerm_storage_container" "container" {
  name                  = "public-container"
  storage_account_name  = azurerm_storage_account.storage.name
  container_access_type = "blob"
}

resource "azurerm_storage_blob" "example_blob" {
  name                   = "index.html"
  storage_account_name   = azurerm_storage_account.storage.name
  storage_container_name = azurerm_storage_container.container.name
  type                   = "Block"
  source                 = "${path.module}/index.html" # make sure this file exists
  content_type           = "text/html"
}

output "blob_url" {
  value = "https://${azurerm_storage_account.storage.name}.blob.core.windows.net/${azurerm_storage_container.container.name}/${azurerm_storage_blob.example_blob.name}"
}
