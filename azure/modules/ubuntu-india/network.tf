# Reference kulland-dns resource group
data "azurerm_resource_group" "kulland_dns" {
  count               = var.enable_dns == 1 ? 1 : 0
  name                = "kulland-dns"
}

# Reference kulland-dns zone
data "azurerm_dns_zone" "zone" {
  count               = var.enable_dns == 1 ? 1 : 0
  name                = "kulland.info"
  resource_group_name = data.azurerm_resource_group.kulland_dns[0].name
}

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

# Create a DNS A record pointing to the BIG-IP Mgmt Public IP
resource "azurerm_dns_a_record" "ubuntu" {
  count               = var.enable_dns == 1 ? 1 : 0
  name                = "ubuntu-smg-india"
  zone_name           = data.azurerm_dns_zone.zone[0].name
  resource_group_name = data.azurerm_resource_group.kulland_dns[0].name
  ttl                 = 60
  records             = [resource.azurerm_public_ip.management_pubip.ip_address]
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
    destination_port_ranges    = ["22","80", "8080", "8081", "3001", "3003"]
    source_address_prefixes    = concat(var.adminSrcAddr, var.REtrafficSrcAddr, var.SynMonSrcAddr)
    destination_address_prefix = "*"
  }
  tags = {
    owner = var.resourceOwner
  }
}
/*
resource "azurerm_network_security_group" "internal_nsg" {
  name                = "ubuntu-internal-NSG"
  location            = var.location
  resource_group_name = var.resource_group_name
  tags = {
    owner = var.resourceOwner
  }
}
*/

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
/*
resource "azurerm_network_interface" "internal_nic" {
  name                = "ubuntu-internal-nic"
  location            = var.location
  resource_group_name = var.resource_group_name

  ip_configuration {
    name                          = "internal_nic_configuration"
    subnet_id                     = var.int_subnet_id
    private_ip_address_allocation = "Static"
    private_ip_address            = "172.20.2.50"
    primary                       = true
  }
  ip_configuration {
    name                          = "internal_nic_configuration_1"
    subnet_id                     = var.int_subnet_id
    private_ip_address_allocation = "Static"
    private_ip_address            = "172.20.2.100"
  }
  ip_configuration {
    name                          = "internal_nic_configuration_2"
    subnet_id                     = var.int_subnet_id
    private_ip_address_allocation = "Static"
    private_ip_address            = "172.20.2.101"
  }
  ip_configuration {
    name                          = "internal_nic_configuration_3"
    subnet_id                     = var.int_subnet_id
    private_ip_address_allocation = "Static"
    private_ip_address            = "172.20.2.102"
  }
  ip_configuration {
    name                          = "internal_nic_configuration_4"
    subnet_id                     = var.int_subnet_id
    private_ip_address_allocation = "Static"
    private_ip_address            = "172.20.2.103"
  }
  ip_configuration {
    name                          = "internal_nic_configuration_5"
    subnet_id                     = var.int_subnet_id
    private_ip_address_allocation = "Static"
    private_ip_address            = "172.20.2.104"
  }
  tags = {
    owner = var.resourceOwner
  }
}
*/

# Connect the security group to the network interface
resource "azurerm_network_interface_security_group_association" "mgmt" {
  network_interface_id      = azurerm_network_interface.management_nic.id
  network_security_group_id = azurerm_network_security_group.management_nsg.id
}
/*
resource "azurerm_network_interface_security_group_association" "internal" {
  network_interface_id      = azurerm_network_interface.internal_nic.id
  network_security_group_id = azurerm_network_security_group.internal_nsg.id
}
*/
