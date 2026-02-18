locals {
  vm_instances = flatten([
    for site_key, site in var.sites : [
      for i in range(var.instance_count) : {
        key             = "${site_key}-${i}"
        site_key        = site_key
        index           = i
        location        = site.location
        rg_name         = site.rg_name
        linux_vm_name   = site.linux_vm_name
        token           = site.token[i]
        slo_nic_id      = site.slo_nic_ids[i]
        sli_nic_id      = site.sli_nic_ids[i]
        sli_1_nic_id    = site.sli_1_nic_ids[i]
        external_pub_ip = site.external_public_ip[i]
        cloud_init_dir  = site.cloud_init_dir
      }
    ]
  ])
  vm_instances_map = { for vi in local.vm_instances : vi.key => vi }
}

resource "local_file" "cloud_init" {
  for_each = local.vm_instances_map
  filename = "${path.cwd}/${each.value.cloud_init_dir}/custom-data_${each.value.index}.tpl"
  content  = <<EOF
  #cloud-config
  write_files:
    - path: /etc/vpm/user_data
      permissions: 644
      owner: root
      content: |
        token: ${each.value.token}
        slo_ip: ${each.value.external_pub_ip}
        #slo_gateway: Un-comment and set default gateway for SLO when static IP is  needed.
  EOF
}

resource "azurerm_linux_virtual_machine" "linux_vm" {
  for_each            = local.vm_instances_map
  name                = "${each.value.linux_vm_name}-${each.value.index}"
  location            = each.value.location
  resource_group_name = each.value.rg_name
  network_interface_ids = [
    each.value.slo_nic_id,
    each.value.sli_nic_id,
    each.value.sli_1_nic_id
  ]
  size        = var.linux_vm_instance_size
  custom_data = base64encode(local_file.cloud_init[each.key].content)

  os_disk {
    name                 = "myLinuxDisk-${each.key}"
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "f5-networks"
    offer     = "f5xc_customer_edge"
    sku       = "f5xccebyol_2"
    version   = "latest"
  }

  plan {
    name      = "f5xccebyol_2"
    product   = "f5xc_customer_edge"
    publisher = "f5-networks"
  }

  computer_name  = "${each.value.linux_vm_name}-${each.value.index}"
  admin_username = var.linux-username
  admin_password = var.linux-password

  admin_ssh_key {
    username   = var.linux-username
    public_key = file(var.ssh_key)
  }
  boot_diagnostics {
    storage_account_uri = azurerm_storage_account.storage[each.value.site_key].primary_blob_endpoint
  }
}

