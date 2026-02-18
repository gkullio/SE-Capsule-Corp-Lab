variable "sites" {
  description = "Map of site configurations for CE VMs"
  type = map(object({
    location           = string
    rg_name            = string
    linux_hostname     = string
    linux_vm_name      = string
    token              = list(string)
    slo_nic_ids        = list(string)
    sli_nic_ids        = list(string)
    sli_1_nic_ids      = list(string)
    external_public_ip = list(string)
    cloud_init_dir     = string
  }))
}

variable "instance_count" {}
variable "linux-username" {}
variable "linux-password" {}
variable "linux_vm_instance_size" {}
variable "linux_vm_ssh_username" {}
variable "ssh_key" {}
variable "adminSrcAddr" {}
variable "vpnMgmtSrcAddr" {}
variable "resourceOwner" {}
variable "REtrafficSrcAddr" {}
