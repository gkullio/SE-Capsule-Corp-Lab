output "CE_Outputs" {
  value = {
    for key, site in var.sites : key => {
      SLO_public_ip      = module.azure-vnet.external_public_ip[key]
      SLO_private_ip     = module.azure-vnet.external_private_ip[key]
      SLI_private_ip     = module.azure-vnet.internal_private_ip[key]
      SLI_1_private_ip   = module.azure-vnet.internal_1_private_ip[key]
    }
  }
}

output "Azure_resource_group_urls" {
  value = {
    for key, site in var.sites : key =>
      "https://portal.azure.com/#@/resource/subscriptions/${var.subscription_id}/resourceGroups/${azurerm_resource_group.rg[key].name}/overview"
  }
}

output "CE_HTTPS_access" {
  value = {
    for key, site in var.sites : key =>
      join("\n", [for ip in module.azure-vnet.external_public_ip[key] : "https://${ip}:65500"])
  }
}

output "Ubuntu_SSH_Azure" {
  value = {
    us_ubuntu_ssh     = module.ubuntu-us.management_ssh
  }
}

output "Ubuntu_SSH_AWS" {
  value = {
    india_ubuntu_ssh  = module.ubuntu-india-aws.management_ssh
  }
}

output "XC_LB_Main_lab_access" {
  value = module.xc.XC_LB_FQDN
}