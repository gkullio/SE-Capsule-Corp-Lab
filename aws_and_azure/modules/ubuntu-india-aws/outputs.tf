# Equivalent to azurerm_linux_virtual_machine.kulland_ubuntu_vm.public_ip_address
output "management_public_ip_address" {
  value = aws_eip.management.public_ip
}

# Equivalent to azurerm_public_ip.management_pubip.ip_address (same value in AWS via EIP)
output "management_private_ip_address" {
  value = aws_instance.ubuntu_vm.private_ip
}

# Equivalent to india_app_server_SSH_fqdn
output "management_ssh" {
  value = "ssh ${var.ubuntu_username}@${aws_eip.management.public_ip}"
}
