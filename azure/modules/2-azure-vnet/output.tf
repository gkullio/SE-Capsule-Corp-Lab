############# VNet Name and ID ############

output "vnet_name" {
  description = "Map of site key to VNet name"
  value       = { for key, vnet in azurerm_virtual_network.vnet : key => vnet.name }
}

output "vnet_id" {
  description = "Map of site key to VNet ID"
  value       = { for key, vnet in azurerm_virtual_network.vnet : key => vnet.id }
}

############# Subnet IDs ############

output "mgmt_subnet_id" {
  description = "Map of site key to management subnet ID"
  value       = { for key, s in azurerm_subnet.mgmt : key => s.id }
}

output "ext_subnet_id" {
  description = "Map of site key to external subnet ID"
  value       = { for key, s in azurerm_subnet.ext : key => s.id }
}

output "int_subnet_id" {
  description = "Map of site key to internal subnet ID"
  value       = { for key, s in azurerm_subnet.int : key => s.id }
}

############# Subnet Names ############

output "mgmt_subnet_name" {
  description = "Map of site key to management subnet name"
  value       = { for key, s in azurerm_subnet.mgmt : key => s.name }
}

output "ext_subnet_name" {
  description = "Map of site key to external subnet name"
  value       = { for key, s in azurerm_subnet.ext : key => s.name }
}

output "int_subnet_name" {
  description = "Map of site key to internal subnet name"
  value       = { for key, s in azurerm_subnet.int : key => s.name }
}

############ Public IPs ############

output "external_public_ip" {
  description = "Map of site key to list of external public IPs"
  value = {
    for site_key in keys(var.sites) : site_key => [
      for si_key, si in local.site_instances_map : azurerm_public_ip.external_pubip[si_key].ip_address
      if si.site_key == site_key
    ]
  }
}

output "external_private_ip" {
  description = "Map of site key to list of SLO private IPs"
  value = {
    for site_key in keys(var.sites) : site_key => [
      for si_key, si in local.site_instances_map : azurerm_network_interface.slo_nic[si_key].ip_configuration[0].private_ip_address
      if si.site_key == site_key
    ]
  }
}

output "internal_private_ip" {
  description = "Map of site key to list of SLI private IPs"
  value = {
    for site_key in keys(var.sites) : site_key => [
      for si_key, si in local.site_instances_map : azurerm_network_interface.sli_nic[si_key].ip_configuration[0].private_ip_address
      if si.site_key == site_key
    ]
  }
}

output "internal_1_private_ip" {
  description = "Map of site key to list of SLI-1 private IPs"
  value = {
    for site_key in keys(var.sites) : site_key => [
      for si_key, si in local.site_instances_map : azurerm_network_interface.sli_1_nic[si_key].ip_configuration[0].private_ip_address
      if si.site_key == site_key
    ]
  }
}

############# NIC IDs ############

output "slo_nic_ids" {
  description = "Map of site key to list of SLO NIC IDs"
  value = {
    for site_key in keys(var.sites) : site_key => [
      for si_key, si in local.site_instances_map : azurerm_network_interface.slo_nic[si_key].id
      if si.site_key == site_key
    ]
  }
}

output "sli_nic_ids" {
  description = "Map of site key to list of SLI NIC IDs"
  value = {
    for site_key in keys(var.sites) : site_key => [
      for si_key, si in local.site_instances_map : azurerm_network_interface.sli_nic[si_key].id
      if si.site_key == site_key
    ]
  }
}

output "sli_1_nic_ids" {
  description = "Map of site key to list of SLI-1 NIC IDs"
  value = {
    for site_key in keys(var.sites) : site_key => [
      for si_key, si in local.site_instances_map : azurerm_network_interface.sli_1_nic[si_key].id
      if si.site_key == site_key
    ]
  }
}
