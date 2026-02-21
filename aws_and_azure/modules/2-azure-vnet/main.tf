locals {
  site_instances = flatten([
    for site_key, site in var.sites : [
      for i in range(var.instance_count) : {
        key             = "${site_key}-${i}"
        site_key        = site_key
        index           = i
        rg_name         = site.rg_name
        location        = site.location
        slo_ip_prefix   = site.slo_ip_prefix
        sli_ip_prefix   = site.sli_ip_prefix
        sli_1_ip_prefix = site.sli_1_ip_prefix
        slo_ip_offset   = site.slo_ip_offset
        sli_ip_offset   = site.sli_ip_offset
        sli_1_ip_offset = site.sli_1_ip_offset
      }
    ]
  ])
  site_instances_map = { for si in local.site_instances : si.key => si }
}



##################### Virtual Networks ####################

resource "azurerm_virtual_network" "vnet" {
  for_each            = var.sites
  name                = each.value.vnet_name
  resource_group_name = each.value.rg_name
  location            = each.value.location
  address_space       = [each.value.vnet_address_space]
}

##################### Subnets ####################

resource "azurerm_subnet" "mgmt" {
  for_each             = var.sites
  name                 = each.value.mgmt_subnet_name
  resource_group_name  = each.value.rg_name
  virtual_network_name = azurerm_virtual_network.vnet[each.key].name
  address_prefixes     = [each.value.mgmt_address_space]
}

resource "azurerm_subnet" "ext" {
  for_each             = var.sites
  name                 = each.value.ext_subnet_name
  resource_group_name  = each.value.rg_name
  virtual_network_name = azurerm_virtual_network.vnet[each.key].name
  address_prefixes     = [each.value.ext_address_space]
}

resource "azurerm_subnet" "int" {
  for_each             = var.sites
  name                 = each.value.int_subnet_name
  resource_group_name  = each.value.rg_name
  virtual_network_name = azurerm_virtual_network.vnet[each.key].name
  address_prefixes     = [each.value.int_address_space]
}

##################### Public IPs ####################

resource "azurerm_public_ip" "external_pubip" {
  for_each            = local.site_instances_map
  name                = "${each.value.rg_name}-pubip-${each.value.index}"
  location            = each.value.location
  resource_group_name = each.value.rg_name
  allocation_method   = "Static"
  sku                 = "Standard"
}

##################### Network Security Groups ####################

resource "azurerm_network_security_group" "external_nsg" {
  for_each            = var.sites
  name                = "${each.value.rg_name}-external-NSG"
  location            = each.value.location
  resource_group_name = each.value.rg_name

  security_rule {
    name                       = "ce_UI_access"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "65500"
    source_address_prefixes    = var.adminSrcAddr
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "IPSEC_Port"
    priority                   = 1002
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Udp"
    source_port_range          = "*"
    destination_port_range     = "4500"
    source_address_prefixes    = [for k, pip in azurerm_public_ip.external_pubip : pip.ip_address if local.site_instances_map[k].site_key != each.key]
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "NTP_Port"
    priority                   = 1234
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Udp"
    source_port_range          = "*"
    destination_port_range     = "123"
    source_address_prefixes    = var.REtrafficSrcAddr
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "https-http"
    priority                   = 1020
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_ranges    = ["80", "443", "8080", "5013"]
    source_address_prefixes    = var.adminSrcAddr
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "vpn_ip_ssh_access"
    priority                   = 1007
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefixes    = var.adminSrcAddr
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "vpn_ip_icmp_access"
    priority                   = 1009
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Icmp"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  tags = {
    owner = var.resourceOwner
  }
}

resource "azurerm_network_security_group" "internal_nsg" {
  for_each            = var.sites
  name                = "${each.value.rg_name}-internal-NSG"
  location            = each.value.location
  resource_group_name = each.value.rg_name

  tags = {
    owner = var.resourceOwner
  }
}

##################### Network Interfaces ####################

resource "azurerm_network_interface" "slo_nic" {
  for_each              = local.site_instances_map
  name                  = "${each.value.rg_name}-SLO-nic-${each.value.index}"
  location              = each.value.location
  resource_group_name   = each.value.rg_name
  ip_forwarding_enabled = true

  ip_configuration {
    name                          = "${each.value.rg_name}-SLO_configuration-${each.value.index}"
    subnet_id                     = azurerm_subnet.ext[each.value.site_key].id
    private_ip_address_allocation = "Static"
    private_ip_address            = "${each.value.slo_ip_prefix}.${each.value.slo_ip_offset + each.value.index}"
    public_ip_address_id          = azurerm_public_ip.external_pubip[each.key].id
    primary                       = true
  }
}

resource "azurerm_network_interface" "sli_nic" {
  for_each              = local.site_instances_map
  name                  = "${each.value.rg_name}-SLI-nic-${each.value.index}"
  location              = each.value.location
  resource_group_name   = each.value.rg_name
  ip_forwarding_enabled = true

  ip_configuration {
    name                          = "${each.value.rg_name}-SLI_nic_configuration-${each.value.index}"
    subnet_id                     = azurerm_subnet.mgmt[each.value.site_key].id
    private_ip_address_allocation = "Static"
    private_ip_address            = "${each.value.sli_ip_prefix}.${each.value.sli_ip_offset + each.value.index}"
  }
}

resource "azurerm_network_interface" "sli_1_nic" {
  for_each              = local.site_instances_map
  name                  = "${each.value.rg_name}-SLI-1-nic_1-${each.value.index}"
  location              = each.value.location
  resource_group_name   = each.value.rg_name
  ip_forwarding_enabled = true

  ip_configuration {
    name                          = "${each.value.rg_name}-SLI_1_nic_configuration-${each.value.index}"
    subnet_id                     = azurerm_subnet.int[each.value.site_key].id
    private_ip_address_allocation = "Static"
    private_ip_address            = "${each.value.sli_1_ip_prefix}.${each.value.sli_1_ip_offset + each.value.index}"
  }
}

##################### NSG Associations ####################

resource "azurerm_network_interface_security_group_association" "external" {
  for_each                  = local.site_instances_map
  network_interface_id      = azurerm_network_interface.slo_nic[each.key].id
  network_security_group_id = azurerm_network_security_group.external_nsg[each.value.site_key].id
}

resource "azurerm_network_interface_security_group_association" "internal" {
  for_each                  = local.site_instances_map
  network_interface_id      = azurerm_network_interface.sli_nic[each.key].id
  network_security_group_id = azurerm_network_security_group.internal_nsg[each.value.site_key].id
}

resource "azurerm_network_interface_security_group_association" "internal_1" {
  for_each                  = local.site_instances_map
  network_interface_id      = azurerm_network_interface.sli_1_nic[each.key].id
  network_security_group_id = azurerm_network_security_group.internal_nsg[each.value.site_key].id
}
