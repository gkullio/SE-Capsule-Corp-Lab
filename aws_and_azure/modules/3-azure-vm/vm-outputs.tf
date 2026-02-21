output "linux_vm_names" {
  description = "Map of site key to list of Linux VM names"
  value = {
    for site_key in keys(var.sites) : site_key => [
      for vm_key, vm in azurerm_linux_virtual_machine.linux_vm : vm.name
      if startswith(vm_key, "${site_key}-")
    ]
  }
}
