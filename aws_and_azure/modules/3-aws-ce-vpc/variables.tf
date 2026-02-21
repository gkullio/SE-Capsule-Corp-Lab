variable "ce_name" {}
variable "resourceOwner" {}
variable "instance_count" {}
variable "adminSrcAddr" {}
variable "REtrafficSrcAddr" {}

variable "vpc_cidr" {}
variable "ext_subnet_cidr" {}   # SLO - external/public-facing
variable "mgmt_subnet_cidr" {}  # SLI - management
variable "int_subnet_cidr" {}   # SLI-1 - internal

variable "slo_ip_prefix" {}
variable "sli_ip_prefix" {}
variable "sli_1_ip_prefix" {}
variable "slo_ip_offset" {}
variable "sli_ip_offset" {}
variable "sli_1_ip_offset" {}
