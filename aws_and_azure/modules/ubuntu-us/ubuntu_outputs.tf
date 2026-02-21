output "management_public_ip_address" {
  value = azurerm_linux_virtual_machine.kulland_ubuntu_vm.public_ip_address
}
output "management_public_ip_address_different_resource" {
  value = azurerm_public_ip.management_pubip.ip_address
}
output "westus_app_server_SSH_fqdn" {
  value = var.enable_dns == 1 ? trimsuffix(azurerm_dns_a_record.ubuntu[0].fqdn, ".") : "DNS not enabled"
}