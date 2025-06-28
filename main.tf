# Resource Group
resource "azurerm_resource_group" "RG" {
  name     = "custom-RG"
  location = "Central India"
}

# Virtual Network
resource "azurerm_virtual_network" "vnet" {
  name                = "vnet"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.RG.location
  resource_group_name = azurerm_resource_group.RG.name
}

# Public Subnet
resource "azurerm_subnet" "subnet" {
  name                 = "public-subnet"
  resource_group_name  = azurerm_resource_group.RG.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.0.0/24"]
}

# Private Subnet
resource "azurerm_subnet" "private_subnet" {
  name                 = "private-subnet"
  resource_group_name  = azurerm_resource_group.RG.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}

# Network Security Group for Public Subnet
resource "azurerm_network_security_group" "nsg" {
  name                = "public-nsg"
  location            = azurerm_resource_group.RG.location
  resource_group_name = azurerm_resource_group.RG.name

  security_rule {
    name                       = "Allow-SSH"
    priority                   = 1000
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Allow-HTTP"
    priority                   = 1010
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Allow-All"
    priority                   = 1100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Deny-All"
    priority                   = 4096
    direction                  = "Inbound"
    access                     = "Deny"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

# Associate NSG with Public Subnet
resource "azurerm_subnet_network_security_group_association" "subnet_nsg" {
  subnet_id                 = azurerm_subnet.subnet.id
  network_security_group_id = azurerm_network_security_group.nsg.id
}

# Public IP
resource "azurerm_public_ip" "public_ip" {
  name                = "public-ip"
  location            = azurerm_resource_group.RG.location
  resource_group_name = azurerm_resource_group.RG.name
  sku                 = "Basic"
  allocation_method   = "Static"
}

# NIC for Public VM
resource "azurerm_network_interface" "nic" {
  name                = "nic"
  location            = azurerm_resource_group.RG.location
  resource_group_name = azurerm_resource_group.RG.name

  ip_configuration {
    name                          = "ip-config"
    subnet_id                     = azurerm_subnet.subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.public_ip.id
  }
}

# NIC for Private VM
resource "azurerm_network_interface" "private_nic" {
  name                = "private-nic"
  location            = azurerm_resource_group.RG.location
  resource_group_name = azurerm_resource_group.RG.name

  ip_configuration {
    name                          = "private-ip-config"
    subnet_id                     = azurerm_subnet.private_subnet.id
    private_ip_address_allocation = "Dynamic"
  }
}

# Public VM
resource "azurerm_virtual_machine" "main" {
  name                  = "vm"
  location              = azurerm_resource_group.RG.location
  resource_group_name   = azurerm_resource_group.RG.name
  network_interface_ids = [azurerm_network_interface.nic.id]
  vm_size               = "Standard_D1"

  storage_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts"
    version   = "latest"
  }

  storage_os_disk {
    name              = "myosdisk1"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }

  os_profile {
    computer_name  = "vm"
    admin_username = var.admin_username
    admin_password = var.admin_password
  }

  os_profile_linux_config {
    disable_password_authentication = false
  }

  tags = {
    environment = "staging"
  }
}

# Private VM
resource "azurerm_virtual_machine" "private_vm" {
  name                  = "private-vm"
  location              = azurerm_resource_group.RG.location
  resource_group_name   = azurerm_resource_group.RG.name
  network_interface_ids = [azurerm_network_interface.private_nic.id]
  vm_size               = "Standard_D1"

  storage_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts"
    version   = "latest"
  }

  storage_os_disk {
    name              = "private-osdisk"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }

  os_profile {
    computer_name  = "privatevm"
    admin_username = var.admin_username
    admin_password = var.admin_password
  }

  os_profile_linux_config {
    disable_password_authentication = false
    custom_data = filebase64("nginx.sh")
  }

  tags = {
    environment = "internal"
  }
}

# Application Gateway
resource "azurerm_application_gateway" "app_gateway" {
  name                = "app-gateway"
  location            = azurerm_resource_group.RG.location
  resource_group_name = azurerm_resource_group.RG.name

  sku {
    name     = "Standard_v2"
    tier     = "Standard_v2"
    capacity = 2
  }

  gateway_ip_configuration {
    name      = "appgateway-ip-config"
    subnet_id = azurerm_subnet.subnet.id
  }

  frontend_port {
    name = "frontend-port"
    port = 80
  }

  frontend_ip_configuration {
    name                 = "frontend-ip"
    public_ip_address_id = azurerm_public_ip.public_ip.id
  }

  backend_address_pool {
    name = "backend-pool"
  }

  backend_http_settings {
    name                  = "http-setting"
    cookie_based_affinity = "Disabled"
    port                  = 80
    protocol              = "Http"
    request_timeout       = 20
  }

  http_listener {
    name                           = "http-listener"
    frontend_ip_configuration_name = "frontend-ip"
    frontend_port_name             = "frontend-port"
    protocol                       = "Http"
  }

  request_routing_rule {
    name                       = "http-rule"
    rule_type                  = "Basic"
    http_listener_name         = "http-listener"
    backend_address_pool_name  = "backend-pool"
    backend_http_settings_name = "http-setting"
  }
}

# VMSS
resource "azurerm_linux_virtual_machine_scale_set" "vmss" {
  name                = "vmss"
  location            = azurerm_resource_group.RG.location
  resource_group_name = azurerm_resource_group.RG.name
  sku                 = "Standard_B1s"
  instances           = 2
  admin_username      = var.admin_username
  admin_password      = var.admin_password

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "22_04-lts"
    version   = "latest"
  }

  os_disk {
    storage_account_type = "Standard_LRS"
    caching              = "ReadWrite"
  }

  os_profile_linux_config {
    disable_password_authentication = false
    custom_data = filebase64("nginx.sh")
  }

  network_interface {
    name    = "vmss-nic"
    primary = true

    ip_configuration {
      name      = "vmss-ipconfig"
      subnet_id = azurerm_subnet.subnet.id
      application_gateway_backend_address_pool_ids = [
        azurerm_application_gateway.app_gateway.backend_address_pool[0].id
      ]
    }
  }
}

# Output
output "public_ip" {
  value       = azurerm_public_ip.public_ip.ip_address
  description = "Public IP of Application Gateway"
}
