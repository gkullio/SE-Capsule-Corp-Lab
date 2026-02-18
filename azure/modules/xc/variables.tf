########################### VARIABLES ####################################
variable "se_namespace" {
  description = "The namespace in which resources are created"
}
variable "delegated_dns_domain" {
  default = "amer-ent.f5demos.com"
}
variable "tenant" {}