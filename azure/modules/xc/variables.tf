########################### VARIABLES ####################################
variable "se_namespace" {
  description = "The namespace in which resources are created"
}
variable "delegated_dns_domain" {
  default = "amer-ent.f5demos.com"
}
variable "tenant" {}
variable "us_site_name" {
  description = "Full name of the US SMSv2 site"
}
variable "ubuntu_us_public_ip" {}
