variable "ce_name" {}
variable "resourceOwner" {}
variable "instance_count" {}
variable "instance_type" {}
variable "linux_username" {}
variable "linux_password" {}
variable "ssh_key" {}
variable "cloud_init_dir" {}

# Token list from module.smsv2.token_ids["in"]
variable "tokens" {
  type = list(string)
}

# ENI IDs and public IPs from module.india-ce-vpc
variable "slo_eni_ids" {
  type = list(string)
}
variable "sli_eni_ids" {
  type = list(string)
}
variable "sli_1_eni_ids" {
  type = list(string)
}
variable "external_public_ip" {
  type = list(string)
}

# F5 XC CE AMI ID for ap-south-1.
# Subscribe at: https://aws.amazon.com/marketplace/pp/prodview-f5xc-ce
# Then find the AMI ID in your region via:
#   aws ec2 describe-images --owners aws-marketplace \
#     --filters "Name=name,Values=*f5xc*ce*" --region ap-south-1
variable "ce_ami_id" {}
