variable "adminSrcAddr" {}
variable "resourceOwner" {}
variable "ubuntu_hostname" {}
variable "ubuntu_username" {}
variable "ubuntu_instance_type" {}
variable "ubuntu_name" {}
variable "ssh_public_key" {}
variable "REtrafficSrcAddr" {}
variable "SynMonSrcAddr" {}
variable "enable_dns" {}

variable "vpc_cidr" {}
variable "mgmt_subnet_cidr" {}
variable "int_subnet_cidr" {}

variable "route53_zone_id" {
  default = ""
}
