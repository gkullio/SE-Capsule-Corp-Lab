##################### AWS Key Pair #####################

# Equivalent to admin_ssh_key block in azurerm_linux_virtual_machine
resource "aws_key_pair" "ubuntu" {
  key_name   = "${var.ubuntu_name}-keypair"
  public_key = file(var.ssh_public_key)
}

##################### Ubuntu 22.04 AMI Lookup #####################

# Equivalent to source_image_reference in azurerm_linux_virtual_machine
# Owner 099720109477 = Canonical (Ubuntu official)
data "aws_ami" "ubuntu_22_04" {
  most_recent = true
  owners      = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

##################### EC2 Instance #####################

# Equivalent to azurerm_linux_virtual_machine "kulland_ubuntu_vm"
resource "aws_instance" "ubuntu_vm" {
  ami                    = data.aws_ami.ubuntu_22_04.id
  instance_type          = var.ubuntu_instance_type
  subnet_id              = aws_subnet.mgmt.id
  vpc_security_group_ids = [aws_security_group.management_sg.id]
  key_name               = aws_key_pair.ubuntu.key_name

  # Equivalent to custom_data = filebase64("${path.module}/onboard.tpl")
  user_data = filebase64("${path.module}/onboard.tpl")

  root_block_device {
    volume_type = "gp3"
    volume_size = 30
  }

  tags = {
    Name  = var.ubuntu_name
    owner = var.resourceOwner
  }
}
