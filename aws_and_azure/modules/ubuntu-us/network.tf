# Create public IPs
resource "azurerm_public_ip" "management_pubip" {
  name                = "ubuntu-management_pubip"
  location            = var.location
  resource_group_name = var.resource_group_name
  allocation_method   = "Static"   # Static is required due to the use of the Standard sku
  sku                 = "Standard" # the Standard sku is required due to the use of availability zones
  tags = {
    owner = var.resourceOwner
  }
}

# Create Network Security Group and rule
resource "azurerm_network_security_group" "management_nsg" {
  name                = "ubuntu-mgmt-NSG"
  location            = var.location
  resource_group_name = var.resource_group_name

  security_rule {
    name                       = "SSH-WebUI"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_ranges    = ["22", "80","8080", "8081", "3000", "3001", "3002"]
    source_address_prefixes    = concat(var.adminSrcAddr, var.REtrafficSrcAddr, var.SynMonSrcAddr)
    destination_address_prefix = "*"
  }
  tags = {
    owner = var.resourceOwner
  }
}

# Create network interface
resource "azurerm_network_interface" "management_nic" {
  name                = "ubuntu-management-nic"
  location            = var.location
  resource_group_name = var.resource_group_name

  ip_configuration {
    name                          = "managenment_nic_configuration"
    subnet_id                     = var.mgmt_subnet_id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.management_pubip.id
  }
  tags = {
    owner = var.resourceOwner
  }
}

# Connect the security group to the network interface
resource "azurerm_network_interface_security_group_association" "mgmt" {
  network_interface_id      = azurerm_network_interface.management_nic.id
  network_security_group_id = azurerm_network_security_group.management_nsg.id
}

