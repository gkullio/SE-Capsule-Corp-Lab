# Equivalent to module.azure-vnet.external_public_ip["in"]
output "external_public_ip" {
  description = "List of SLO Elastic IP addresses (one per CE instance)"
  value       = [for key, eip in aws_eip.slo : eip.public_ip]
}

# Equivalent to module.azure-vnet.slo_nic_ids["in"]
output "slo_eni_ids" {
  description = "List of SLO ENI IDs (one per CE instance)"
  value       = [for key, eni in aws_network_interface.slo : eni.id]
}

# Equivalent to module.azure-vnet.sli_nic_ids["in"]
output "sli_eni_ids" {
  description = "List of SLI ENI IDs (one per CE instance)"
  value       = [for key, eni in aws_network_interface.sli : eni.id]
}

# Equivalent to module.azure-vnet.sli_1_nic_ids["in"]
output "sli_1_eni_ids" {
  description = "List of SLI-1 ENI IDs (one per CE instance)"
  value       = [for key, eni in aws_network_interface.sli_1 : eni.id]
}
