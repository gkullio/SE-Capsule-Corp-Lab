############### Site Configuration ###############

variable "sites" {
  description = "Map of site configurations"
  type = map(object({
    rg_name            = string
    location           = string
    vnet_name          = string
    vnet_address_space = string
    mgmt_subnet_name   = string
    mgmt_address_space  = string
    ext_subnet_name     = string
    ext_address_space   = string
    int_subnet_name     = string
    int_address_space   = string
    slo_ip_prefix       = string
    sli_ip_prefix       = string
    sli_1_ip_prefix     = string
    slo_ip_offset       = number
    sli_ip_offset       = number
    sli_1_ip_offset     = number
  }))
}

############### Common Variables ###############

variable "adminSrcAddr" {}
variable "resourceOwner" {}
variable "linux-username" {}
variable "linux-password" {}
variable "ssh_key" {}
variable "REtrafficSrcAddr" {}
variable "instance_count" {}
variable "enable_dns" {}
