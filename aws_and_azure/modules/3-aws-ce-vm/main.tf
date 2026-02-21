locals {
  # Mirrors the vm_instances_map pattern from 3-azure-vm
  vm_instances = [
    for i in range(var.instance_count) : {
      key                = "${var.ce_name}-${i}"
      index              = i
      token              = var.tokens[i]
      slo_eni_id         = var.slo_eni_ids[i]
      sli_eni_id         = var.sli_eni_ids[i]
      sli_1_eni_id       = var.sli_1_eni_ids[i]
      external_public_ip = var.external_public_ip[i]
    }
  ]
  vm_instances_map = { for vi in local.vm_instances : vi.key => vi }
}

##################### Cloud-Init Files #####################

# Mirrors local_file.cloud_init in 3-azure-vm — writes token file locally
# and also renders the user_data for the EC2 instance
resource "local_file" "cloud_init" {
  for_each = local.vm_instances_map
  filename = "${path.cwd}/${var.cloud_init_dir}/custom-data_${each.value.index}.tpl"
  content = templatefile("${path.module}/cloud-init.tpl", {
    token  = each.value.token
    slo_ip = each.value.external_public_ip
  })
}

##################### AWS Key Pair #####################

resource "aws_key_pair" "ce" {
  key_name   = "${var.ce_name}-keypair"
  public_key = file(var.ssh_key)
}

##################### EC2 Instances #####################

# Equivalent to azurerm_linux_virtual_machine "linux_vm" in 3-azure-vm
# The F5 XC CE image must be subscribed to via AWS Marketplace before use.
resource "aws_instance" "ce" {
  for_each      = local.vm_instances_map
  ami           = var.ce_ami_id
  instance_type = var.instance_type
  key_name      = aws_key_pair.ce.key_name

  # SLO is eth0 (primary), SLI is eth1, SLI-1 is eth2
  # Equivalent to network_interface_ids in azurerm_linux_virtual_machine
  network_interface {
    network_interface_id = each.value.slo_eni_id
    device_index         = 0
  }

  network_interface {
    network_interface_id = each.value.sli_eni_id
    device_index         = 1
  }

  network_interface {
    network_interface_id = each.value.sli_1_eni_id
    device_index         = 2
  }

  # Equivalent to custom_data = base64encode(local_file.cloud_init[each.key].content)
  user_data = base64encode(local_file.cloud_init[each.key].content)

  root_block_device {
    volume_type = "gp3"
    volume_size = 40
  }

  tags = {
    Name  = "${var.ce_name}-${each.value.index}"
    owner = var.resourceOwner
  }

  depends_on = [local_file.cloud_init]
}
