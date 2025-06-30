# Data source for existing resource group
data "azurerm_resource_group" "example" {
  name = "custom-RG"
}

# Data source for existing virtual network
data "azurerm_virtual_network" "example" {
  name                = "vnet"
  resource_group_name = data.azurerm_resource_group.example.name
}

# Data source for private subnet (used by MySQL)
data "azurerm_subnet" "private_subnet" {
  name                 = "private-subnet"
  virtual_network_name = data.azurerm_virtual_network.example.name
  resource_group_name  = data.azurerm_resource_group.example.name
}

# Create Private DNS Zone for MySQL Flexible Server
resource "azurerm_private_dns_zone" "mysql_flex" {
  name                = "privatelink.mysql.database.azure.com"
  resource_group_name = data.azurerm_resource_group.example.name
}

# Link DNS zone to virtual network
resource "azurerm_private_dns_zone_virtual_network_link" "mysql_dns_link" {
  name                  = "mysql-dns-link"
  resource_group_name   = data.azurerm_resource_group.example.name
  private_dns_zone_name = azurerm_private_dns_zone.mysql_flex.name
  virtual_network_id    = data.azurerm_virtual_network.example.id
}

# MySQL Flexible Server
resource "azurerm_mysql_flexible_server" "mysql" {
  name                   = "mysql-flexible-server"
  location               = data.azurerm_resource_group.example.location
  resource_group_name    = data.azurerm_resource_group.example.name
  administrator_login    = var.mysql_admin_username
  administrator_password = var.mysql_admin_password
  sku_name               = "B1ms"
  version                = "8.0"

  storage {
    size_gb = 32
  }

  high_availability {
    mode = "Disabled"
  }

  network {
    delegated_subnet_id = data.azurerm_subnet.private_subnet.id
    private_dns_zone_arm_resource_id = azurerm_private_dns_zone.mysql_flex.id
  }

  zone = "1"
}
