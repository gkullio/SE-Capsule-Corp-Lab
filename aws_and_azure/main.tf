##################### Collect Public IP address #####################

data "http" "my_ip" {
  url = "https://checkip.amazonaws.com"
}

##################### Azure RG Configuration #####################

resource "random_id" "site" {
  for_each    = var.sites
  byte_length = 1
}

resource "random_id" "main" {  
  byte_length = 1
}

# "in" (India) is on AWS — no Azure resource group needed for it
resource "azurerm_resource_group" "rg" {
  for_each = { for k, v in var.sites : k => v if k != "in" }
  name     = "${var.se_namespace}-${each.value.rg_name}-${random_id.site[each.key].dec}"
  location = each.value.location
}

locals {
  instance_count = var.instance_count
  effective_ha   = var.instance_count == 1 ? false : var.ha  
  my_public_ip = "${chomp(data.http.my_ip.response_body)}/32"
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
      name         = "${var.se_namespace}-${site.name}-${random_id.site[key].dec}"
      region_label = site.region_label
      cloud        = key == "in" ? "aws" : "azure"
    }
  }
}

##################### Create XC Load Balancer ####################

module "xc" {
  depends_on            = [module.ubuntu-us]
  source                = "./modules/xc"
  tenant                = var.tenant
  se_namespace          = var.se_namespace
  delegated_dns_domain  = var.delegated_dns_domain
  us_site_name          = module.smsv2.us_site_name
  ubuntu_us_public_ip   = module.ubuntu-us.management_public_ip_address

}

##################### Azure VNET ####################

module "azure-vnet" {
  depends_on = [azurerm_resource_group.rg]
  source     = "./modules/2-azure-vnet"

  # Filter "in" — India CE is on AWS, not Azure
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
    } if key != "in"
  }

  linux-username   = var.linux-username
  linux-password   = var.linux-password
  instance_count   = var.instance_count
  ssh_key          = var.ssh_publickey
  REtrafficSrcAddr = var.REtrafficSrcAddr
  adminSrcAddr     = [local.my_public_ip]
  resourceOwner    = var.resourceOwner
  enable_dns       = var.enable_dns
}

##################### Azure CE VMs ####################

module "azure-vm" {
  depends_on = [azurerm_resource_group.rg, module.azure-vnet]
  source     = "./modules/3-azure-vm"

  # Filter "in" — India CE is on AWS (see module "india-ce-vm" below)
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
      cloud_init_dir     = lookup({ "us" = "ce-token-west-city" }, key)
    } if key != "in"
  }

  instance_count         = var.instance_count
  linux-username         = var.linux-username
  linux-password         = var.linux-password
  linux_vm_instance_size = var.linux_vm_instance_size
  linux_vm_ssh_username  = var.linux_vm_ssh_username
  ssh_key                = var.ssh_publickey
  adminSrcAddr           = [local.my_public_ip]
  resourceOwner          = var.resourceOwner
  REtrafficSrcAddr       = var.REtrafficSrcAddr
}

##################### India CE on AWS - Networking ####################

module "india-ce-vpc" {
  source         = "./modules/3-aws-ce-vpc"
  ce_name        = "${var.se_namespace}-${var.sites["in"].name}-${random_id.site["in"].dec}"
  resourceOwner  = var.resourceOwner
  instance_count = var.instance_count
  adminSrcAddr   = [local.my_public_ip]
  REtrafficSrcAddr = var.REtrafficSrcAddr

  vpc_cidr        = var.india_aws_ce_vpc_cidr
  ext_subnet_cidr = var.india_aws_ce_ext_subnet_cidr
  mgmt_subnet_cidr = var.india_aws_ce_mgmt_subnet_cidr
  int_subnet_cidr = var.india_aws_ce_int_subnet_cidr

  slo_ip_prefix   = var.sites["in"].slo_ip_prefix
  sli_ip_prefix   = var.sites["in"].sli_ip_prefix
  sli_1_ip_prefix = var.sites["in"].sli_1_ip_prefix
  slo_ip_offset   = var.sites["in"].slo_ip_offset
  sli_ip_offset   = var.sites["in"].sli_ip_offset
  sli_1_ip_offset = var.sites["in"].sli_1_ip_offset
}

##################### India CE on AWS - EC2 Instance ####################

module "india-ce-vm" {
  depends_on     = [module.india-ce-vpc, module.smsv2]
  source         = "./modules/3-aws-ce-vm"
  ce_name        = "${var.se_namespace}-${var.sites["in"].name}-${random_id.site["in"].dec}"
  resourceOwner  = var.resourceOwner
  instance_count = var.instance_count
  instance_type  = var.linux_vm_instance_size
  linux_username = var.linux-username
  linux_password = var.linux-password
  ssh_key        = var.ssh_publickey
  cloud_init_dir = "ce-token-frieza-force"
  ce_ami_id      = var.india_aws_ce_ami_id

  tokens             = module.smsv2.token_ids["in"]
  slo_eni_ids        = module.india-ce-vpc.slo_eni_ids
  sli_eni_ids        = module.india-ce-vpc.sli_eni_ids
  sli_1_eni_ids      = module.india-ce-vpc.sli_1_eni_ids
  external_public_ip = module.india-ce-vpc.external_public_ip
}

##################### Ubuntu App Servers ####################

module "ubuntu-india" {
  source               = "./modules/ubuntu-india-aws"
  ubuntu_instance_type = var.aws_ubuntu_instance_type
  ubuntu_hostname      = var.sites["in"].ubuntu_hostname
  ubuntu_name          = var.sites["in"].ubuntu_name
  ubuntu_username      = var.ubuntu-username
  resourceOwner        = var.resourceOwner
  adminSrcAddr         = [local.my_public_ip]
  REtrafficSrcAddr     = var.REtrafficSrcAddr
  SynMonSrcAddr        = var.SynMonSrcAddr
  ssh_public_key       = var.ssh_publickey
  enable_dns           = var.enable_dns
  route53_zone_id      = var.route53_zone_id
  vpc_cidr             = var.india_aws_vpc_cidr
  mgmt_subnet_cidr     = var.india_aws_mgmt_subnet_cidr
  int_subnet_cidr      = var.india_aws_int_subnet_cidr
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
  adminSrcAddr         = [local.my_public_ip]
  REtrafficSrcAddr     = var.REtrafficSrcAddr
  SynMonSrcAddr        = var.SynMonSrcAddr
  resource_group_name  = azurerm_resource_group.rg["us"].name
  location             = azurerm_resource_group.rg["us"].location
  ubuntu_name          = var.sites["us"].ubuntu_name
  ssh_key              = var.ssh_publickey
  enable_dns           = var.enable_dns
}

