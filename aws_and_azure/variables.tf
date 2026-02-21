#################### Site Configuration Map ####################

variable "sites" {
  description = "Map of site configurations keyed by site identifier (e.g., 'us', 'in')"
  type = map(object({
    rg_name            = string
    location           = string
    name               = string
    vnet_name          = string
    vnet_address_space = string
    mgmt_subnet_name   = string
    mgmt_address_space  = string
    ext_subnet_name     = string
    ext_address_space   = string
    int_subnet_name     = string
    int_address_space   = string
    linux_hostname      = string
    linux_vm_name       = string
    ubuntu_hostname     = string
    ubuntu_name         = string
    region_label        = string
    slo_ip_prefix       = string
    sli_ip_prefix       = string
    sli_1_ip_prefix     = string
    slo_ip_offset       = number
    sli_ip_offset       = number
    sli_1_ip_offset     = number
  }))
}

#################### Common Variables ####################

variable "resourceOwner" {}
variable "instance_count" {}

#################### Azure Service Principal ####################

variable "client_id" {}
variable "client_secret" {}
variable "tenant_id" {}
variable "subscription_id" {}

#################### SMSv2 Site ####################

variable "tenant" {}
variable "ha" {}
variable "namespace" {}
variable "sw" {}
variable "os" {}

#################### XC Load Balancer ####################

variable "se_namespace" {}
variable "delegated_dns_domain" {}

#################### Azure VM Common Variables ####################

variable "linux-username" {}
variable "linux-password" {}
variable "linux_vm_instance_size" {}
variable "linux_vm_ssh_username" {}
variable "ssh_publickey" {}
variable "ubuntu_instance_size" {}
variable "ubuntu-username" {}
variable "ubuntu-password" {}
variable "enable_dns" {}

#################### Source Addresses for NSG Rules ####################

variable "REtrafficSrcAddr" {}
variable "SynMonSrcAddr" {}

#################### AWS India Site - Ubuntu App Server ####################

variable "aws_region" {}
variable "aws_ubuntu_instance_type" {}
variable "india_aws_vpc_cidr" {}
variable "india_aws_mgmt_subnet_cidr" {}
variable "india_aws_int_subnet_cidr" {}
variable "route53_zone_id" {
  default = ""
}

#################### AWS India Site - CE Node ####################

variable "india_aws_ce_vpc_cidr" {}
variable "india_aws_ce_ext_subnet_cidr" {}
variable "india_aws_ce_mgmt_subnet_cidr" {}
variable "india_aws_ce_int_subnet_cidr" {}

# Subscribe at AWS Marketplace, then find the AMI ID for ap-south-1:
#   aws ec2 describe-images --owners aws-marketplace \
#     --filters "Name=name,Values=*f5xc*ce*" --region ap-south-1
variable "india_aws_ce_ami_id" {}