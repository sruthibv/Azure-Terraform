resource "azurerm_resource_group" "rg" {
  name     = "example-rg"
  location = "East US"
}

resource "azurerm_storage_account" "storage" {
  name                     = "examplestoragenvk" # must be unique globally
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = azurerm_resource_group.rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  allow_blob_public_access = true
}

resource "azurerm_storage_container" "container" {
  name                  = "public-container"
  storage_account_name  = azurerm_storage_account.storage.name
  container_access_type = "blob"
}

resource "azurerm_storage_blob" "example_blob" {
  name                   = "hello.txt"
  storage_account_name   = azurerm_storage_account.storage.name
  storage_container_name = azurerm_storage_container.container.name
  type                   = "Block"
  source                 = "${path.module}/hello.txt" # local file path
}

output "blob_url" {
  value = "https://${azurerm_storage_account.storage.name}.blob.core.windows.net/${azurerm_storage_container.container.name}/${azurerm_storage_blob.example_blob.name}"
}
