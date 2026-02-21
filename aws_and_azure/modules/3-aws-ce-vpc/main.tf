locals {
  # Build a flat list of CE instances (mirrors azure-vnet pattern)
  ce_instances = [
    for i in range(var.instance_count) : {
      key             = "${var.ce_name}-${i}"
      index           = i
      slo_private_ip  = "${var.slo_ip_prefix}.${var.slo_ip_offset + i}"
      sli_private_ip  = "${var.sli_ip_prefix}.${var.sli_ip_offset + i}"
      sli_1_private_ip = "${var.sli_1_ip_prefix}.${var.sli_1_ip_offset + i}"
    }
  ]
  ce_instances_map = { for ci in local.ce_instances : ci.key => ci }
}

##################### VPC #####################

resource "aws_vpc" "ce" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name  = "${var.ce_name}-vpc"
    owner = var.resourceOwner
  }
}

##################### Internet Gateway #####################

resource "aws_internet_gateway" "ce" {
  vpc_id = aws_vpc.ce.id

  tags = {
    Name  = "${var.ce_name}-igw"
    owner = var.resourceOwner
  }
}

##################### Subnets #####################

# External subnet - SLO (equivalent to azurerm_subnet.ext)
resource "aws_subnet" "ext" {
  vpc_id                  = aws_vpc.ce.id
  cidr_block              = var.ext_subnet_cidr
  map_public_ip_on_launch = false

  tags = {
    Name  = "${var.ce_name}-ext-subnet"
    owner = var.resourceOwner
  }
}

# Management subnet - SLI (equivalent to azurerm_subnet.mgmt)
resource "aws_subnet" "mgmt" {
  vpc_id     = aws_vpc.ce.id
  cidr_block = var.mgmt_subnet_cidr

  tags = {
    Name  = "${var.ce_name}-mgmt-subnet"
    owner = var.resourceOwner
  }
}

# Internal subnet - SLI-1 (equivalent to azurerm_subnet.int)
resource "aws_subnet" "int" {
  vpc_id     = aws_vpc.ce.id
  cidr_block = var.int_subnet_cidr

  tags = {
    Name  = "${var.ce_name}-int-subnet"
    owner = var.resourceOwner
  }
}

##################### Route Tables #####################

resource "aws_route_table" "ext" {
  vpc_id = aws_vpc.ce.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.ce.id
  }

  tags = {
    Name  = "${var.ce_name}-ext-rt"
    owner = var.resourceOwner
  }
}

resource "aws_route_table_association" "ext" {
  subnet_id      = aws_subnet.ext.id
  route_table_id = aws_route_table.ext.id
}

##################### Security Groups #####################

# Equivalent to azurerm_network_security_group "external_nsg"
resource "aws_security_group" "external_sg" {
  name        = "${var.ce_name}-external-sg"
  description = "F5 XC CE external (SLO) security group"
  vpc_id      = aws_vpc.ce.id

  ingress {
    description = "CE UI"
    from_port   = 65500
    to_port     = 65500
    protocol    = "tcp"
    cidr_blocks = var.adminSrcAddr
  }

  ingress {
    description = "IPsec - allow all sources (CE connects to F5 REs and peer CEs)"
    from_port   = 4500
    to_port     = 4500
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "NTP"
    from_port   = 123
    to_port     = 123
    protocol    = "udp"
    cidr_blocks = var.REtrafficSrcAddr
  }

  ingress {
    description = "HTTP/HTTPS and management ports"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = var.adminSrcAddr
  }

  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = var.adminSrcAddr
  }

  ingress {
    description = "Alt HTTP"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = var.adminSrcAddr
  }

  ingress {
    description = "CE mgmt port 5013"
    from_port   = 5013
    to_port     = 5013
    protocol    = "tcp"
    cidr_blocks = var.adminSrcAddr
  }

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.adminSrcAddr
  }

  ingress {
    description = "ICMP"
    from_port   = -1
    to_port     = -1
    protocol    = "icmp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name  = "${var.ce_name}-external-sg"
    owner = var.resourceOwner
  }
}

# Equivalent to azurerm_network_security_group "internal_nsg"
resource "aws_security_group" "internal_sg" {
  name        = "${var.ce_name}-internal-sg"
  description = "F5 XC CE internal (SLI) security group - allow all VPC traffic"
  vpc_id      = aws_vpc.ce.id

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [var.vpc_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name  = "${var.ce_name}-internal-sg"
    owner = var.resourceOwner
  }
}

##################### Elastic IPs (SLO) #####################

# Equivalent to azurerm_public_ip "external_pubip"
resource "aws_eip" "slo" {
  for_each = local.ce_instances_map
  domain   = "vpc"

  tags = {
    Name  = "${var.ce_name}-slo-eip-${each.value.index}"
    owner = var.resourceOwner
  }
}

##################### Network Interfaces #####################

# SLO ENI - equivalent to azurerm_network_interface "slo_nic"
resource "aws_network_interface" "slo" {
  for_each          = local.ce_instances_map
  subnet_id         = aws_subnet.ext.id
  private_ips       = [each.value.slo_private_ip]
  security_groups   = [aws_security_group.external_sg.id]
  source_dest_check = false

  tags = {
    Name  = "${var.ce_name}-slo-eni-${each.value.index}"
    owner = var.resourceOwner
  }
}

resource "aws_eip_association" "slo" {
  for_each             = local.ce_instances_map
  allocation_id        = aws_eip.slo[each.key].id
  network_interface_id = aws_network_interface.slo[each.key].id
}

# SLI ENI - equivalent to azurerm_network_interface "sli_nic"
resource "aws_network_interface" "sli" {
  for_each          = local.ce_instances_map
  subnet_id         = aws_subnet.mgmt.id
  private_ips       = [each.value.sli_private_ip]
  security_groups   = [aws_security_group.internal_sg.id]
  source_dest_check = false

  tags = {
    Name  = "${var.ce_name}-sli-eni-${each.value.index}"
    owner = var.resourceOwner
  }
}

# SLI-1 ENI - equivalent to azurerm_network_interface "sli_1_nic"
resource "aws_network_interface" "sli_1" {
  for_each          = local.ce_instances_map
  subnet_id         = aws_subnet.int.id
  private_ips       = [each.value.sli_1_private_ip]
  security_groups   = [aws_security_group.internal_sg.id]
  source_dest_check = false

  tags = {
    Name  = "${var.ce_name}-sli-1-eni-${each.value.index}"
    owner = var.resourceOwner
  }
}
