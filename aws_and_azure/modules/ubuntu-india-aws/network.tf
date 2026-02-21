##################### VPC #####################

resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name  = "${var.ubuntu_name}-vpc"
    owner = var.resourceOwner
  }
}

##################### Internet Gateway #####################

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name  = "${var.ubuntu_name}-igw"
    owner = var.resourceOwner
  }
}

##################### Subnets #####################

# Management (public-facing) subnet
resource "aws_subnet" "mgmt" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.mgmt_subnet_cidr
  map_public_ip_on_launch = false

  tags = {
    Name  = "${var.ubuntu_name}-mgmt-subnet"
    owner = var.resourceOwner
  }
}

# Internal subnet
resource "aws_subnet" "internal" {
  vpc_id     = aws_vpc.main.id
  cidr_block = var.int_subnet_cidr

  tags = {
    Name  = "${var.ubuntu_name}-internal-subnet"
    owner = var.resourceOwner
  }
}

##################### Route Tables #####################

resource "aws_route_table" "mgmt" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name  = "${var.ubuntu_name}-mgmt-rt"
    owner = var.resourceOwner
  }
}

resource "aws_route_table_association" "mgmt" {
  subnet_id      = aws_subnet.mgmt.id
  route_table_id = aws_route_table.mgmt.id
}

##################### Security Group #####################

# Equivalent to azurerm_network_security_group "management_nsg"
resource "aws_security_group" "management_sg" {
  name        = "${var.ubuntu_name}-mgmt-sg"
  description = "Allow SSH and app traffic"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = concat(var.adminSrcAddr, var.REtrafficSrcAddr, var.SynMonSrcAddr)
  }

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = concat(var.adminSrcAddr, var.REtrafficSrcAddr, var.SynMonSrcAddr)
  }

  ingress {
    description = "App 8080-8081"
    from_port   = 8080
    to_port     = 8081
    protocol    = "tcp"
    cidr_blocks = concat(var.adminSrcAddr, var.REtrafficSrcAddr, var.SynMonSrcAddr)
  }

  ingress {
    description = "App 3001"
    from_port   = 3001
    to_port     = 3001
    protocol    = "tcp"
    cidr_blocks = concat(var.adminSrcAddr, var.REtrafficSrcAddr, var.SynMonSrcAddr)
  }

  ingress {
    description = "App 3003"
    from_port   = 3003
    to_port     = 3003
    protocol    = "tcp"
    cidr_blocks = concat(var.adminSrcAddr, var.REtrafficSrcAddr, var.SynMonSrcAddr)
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name  = "${var.ubuntu_name}-mgmt-sg"
    owner = var.resourceOwner
  }
}

##################### Elastic IP #####################

# Equivalent to azurerm_public_ip "management_pubip"
resource "aws_eip" "management" {
  domain = "vpc"

  tags = {
    Name  = "${var.ubuntu_name}-mgmt-eip"
    owner = var.resourceOwner
  }
}

resource "aws_eip_association" "management" {
  instance_id   = aws_instance.ubuntu_vm.id
  allocation_id = aws_eip.management.id
}

