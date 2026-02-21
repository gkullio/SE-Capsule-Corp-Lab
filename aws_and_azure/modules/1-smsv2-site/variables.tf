#################### SMSv2 Variables ####################

variable "tenant" {}
variable "ha" {}
variable "namespace" {}
variable "instance_count" {}
variable "ssh_key" {}
variable "sw" {}
variable "admin_password" {}
variable "os" {}

variable "sites" {
  description = "Map of site configs keyed by site id (e.g., 'us', 'in')"
  type = map(object({
    name         = string
    region_label = string
    cloud        = string  # "azure" or "aws"
  }))
}
