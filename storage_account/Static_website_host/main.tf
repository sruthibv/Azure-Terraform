resource "azurerm_resource_group" "rg" {
  name     = "veera-rgs"
  location = "East US"
}

resource "azurerm_storage_account" "storage" {
  name                     = "sruthilovesnaruto" # must be globally unique
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = azurerm_resource_group.rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"

  static_website {
    index_document = "index.html"
  }
}

resource "azurerm_storage_blob" "index_html" {
  name                   = "index.html"
  storage_account_name   = azurerm_storage_account.storage.name
  storage_container_name = "$web"
  type                   = "Block"
  source                 = "${path.module}/index.html"
  content_type           = "text/html"
  
}

output "static_website_url" {
  value = azurerm_storage_account.storage.primary_web_endpoint
}
