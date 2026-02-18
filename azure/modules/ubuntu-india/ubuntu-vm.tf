# Create virtual machine
resource "azurerm_linux_virtual_machine" "kulland_ubuntu_vm" {
  name                    = var.ubuntu_name
  location                = var.location
  resource_group_name     = var.resource_group_name
  network_interface_ids   = [ azurerm_network_interface.management_nic.id ]
  size                    = var.ubuntu_instance_size
  custom_data             = filebase64("${path.module}/onboard.tpl")

  os_disk {
    name                  = "myUbuntuDisk"
    caching               = "ReadWrite"
    storage_account_type  = "Standard_LRS"
  }

  source_image_reference {
    publisher             = "Canonical"
    offer                 = "0001-com-ubuntu-server-jammy"
    sku                   = "22_04-lts-gen2"
    version               = "latest"
  }

  computer_name           = var.ubuntu_hostname
  admin_username          = var.ubuntu_username
  admin_password          = var.ubuntu_password

  admin_ssh_key {
    username              = var.ubuntu_username
    public_key            = file(var.ssh_key)
  }

  boot_diagnostics {
    storage_account_uri   = azurerm_storage_account.my_storage_account.primary_blob_endpoint
  }

  tags = {
    owner                 = var.resourceOwner
  }
}

