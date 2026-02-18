resource "random_id" "site" {
  for_each    = var.sites
  byte_length = 1
}

resource "random_id" "main" {  
  byte_length = 1
}

resource "azurerm_resource_group" "rg" {
  for_each = var.sites
  name     = "${var.se_name}-${each.value.rg_name}-${random_id.site[each.key].dec}"
  location = each.value.location
}

locals {
  instance_count = var.instance_count
  effective_ha   = var.instance_count == 1 ? false : var.ha
}

##################### Create SMSv2 Site ####################

module "smsv2" {
  source         = "./modules/1-smsv2-site"
  tenant         = var.tenant
  ha             = local.effective_ha
  namespace      = var.namespace
  instance_count = var.instance_count
  ssh_key        = var.ssh_publickey
  sw             = var.sw
  admin_password = var.linux-password
  os             = var.os

  sites = {
    for key, site in var.sites : key => {
      name         = "${var.se_name}-${site.name}-${random_id.site[key].dec}"
      region_label = site.region_label
    }
  }
}


##################### Azure VNET ####################

module "azure-vnet" {
  depends_on = [azurerm_resource_group.rg]
  source     = "./modules/2-azure-vnet"

  sites = {
    for key, site in var.sites : key => {
      rg_name             = azurerm_resource_group.rg[key].name
      location            = site.location
      vnet_name           = "${site.vnet_name}-${random_id.site[key].dec}"
      vnet_address_space  = site.vnet_address_space
      mgmt_subnet_name    = "${site.mgmt_subnet_name}-${random_id.site[key].dec}"
      mgmt_address_space  = site.mgmt_address_space
      ext_subnet_name     = "${site.ext_subnet_name}-${random_id.site[key].dec}"
      ext_address_space   = site.ext_address_space
      int_subnet_name     = "${site.int_subnet_name}-${random_id.site[key].dec}"
      int_address_space   = site.int_address_space
      slo_ip_prefix       = site.slo_ip_prefix
      sli_ip_prefix       = site.sli_ip_prefix
      sli_1_ip_prefix     = site.sli_1_ip_prefix
      slo_ip_offset       = site.slo_ip_offset
      sli_ip_offset       = site.sli_ip_offset
      sli_1_ip_offset     = site.sli_1_ip_offset
    }
  }

  linux-username   = var.linux-username
  linux-password   = var.linux-password
  instance_count   = var.instance_count
  ssh_key          = var.ssh_publickey
  REtrafficSrcAddr = var.REtrafficSrcAddr
  adminSrcAddr     = var.adminSrcAddr
  vpnMgmtSrcAddr   = var.vpnMgmtSrcAddr
  resourceOwner    = var.resourceOwner
  enable_dns       = var.enable_dns
}

##################### Azure CE VMs ####################

module "azure-vm" {
  depends_on = [azurerm_resource_group.rg, module.azure-vnet]
  source     = "./modules/3-azure-vm"

  sites = {
    for key, site in var.sites : key => {
      location           = site.location
      rg_name            = azurerm_resource_group.rg[key].name
      linux_hostname     = site.linux_hostname
      linux_vm_name      = "${site.linux_vm_name}-${random_id.site[key].dec}"
      token              = module.smsv2.token_ids[key]
      slo_nic_ids        = module.azure-vnet.slo_nic_ids[key]
      sli_nic_ids        = module.azure-vnet.sli_nic_ids[key]
      sli_1_nic_ids      = module.azure-vnet.sli_1_nic_ids[key]
      external_public_ip = module.azure-vnet.external_public_ip[key]
      cloud_init_dir     = lookup({ "us" = "ce-sms-token-us", "in" = "ce-sms-token-india" }, key)
    }
  }

  instance_count         = var.instance_count
  linux-username         = var.linux-username
  linux-password         = var.linux-password
  linux_vm_instance_size = var.linux_vm_instance_size
  linux_vm_ssh_username  = var.linux_vm_ssh_username
  ssh_key                = var.ssh_publickey
  adminSrcAddr           = var.adminSrcAddr
  vpnMgmtSrcAddr         = var.vpnMgmtSrcAddr
  resourceOwner          = var.resourceOwner
  REtrafficSrcAddr       = var.REtrafficSrcAddr
}

##################### Ubuntu App Servers ####################

module "ubuntu-india" {
  depends_on           = [azurerm_resource_group.rg, module.azure-vnet]
  source               = "./modules/ubuntu-india"
  mgmt_subnet_id       = module.azure-vnet.mgmt_subnet_id["in"]
  int_subnet_id        = module.azure-vnet.int_subnet_id["in"]
  ubuntu_instance_size = var.ubuntu_instance_size
  ubuntu_hostname      = var.sites["in"].ubuntu_hostname
  resourceOwner        = var.resourceOwner
  ubuntu_username      = var.ubuntu-username
  ubuntu_password      = var.ubuntu-password
  adminSrcAddr         = var.vpnMgmtSrcAddr
  resource_group_name  = azurerm_resource_group.rg["in"].name
  location             = azurerm_resource_group.rg["in"].location
  ubuntu_name          = var.sites["in"].ubuntu_name
  ssh_key              = var.ssh_publickey
  enable_dns           = var.enable_dns
}

module "ubuntu-us" {
  depends_on           = [azurerm_resource_group.rg, module.azure-vnet]
  source               = "./modules/ubuntu-us"
  mgmt_subnet_id       = module.azure-vnet.mgmt_subnet_id["us"]
  int_subnet_id        = module.azure-vnet.int_subnet_id["us"]
  ubuntu_instance_size = var.ubuntu_instance_size
  ubuntu_hostname      = var.sites["us"].ubuntu_hostname
  resourceOwner        = var.resourceOwner
  ubuntu_username      = var.ubuntu-username
  ubuntu_password      = var.ubuntu-password
  adminSrcAddr         = var.vpnMgmtSrcAddr
  resource_group_name  = azurerm_resource_group.rg["us"].name
  location             = azurerm_resource_group.rg["us"].location
  ubuntu_name          = var.sites["us"].ubuntu_name
  ssh_key              = var.ssh_publickey
  enable_dns           = var.enable_dns
}

