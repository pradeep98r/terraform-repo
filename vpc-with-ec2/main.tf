provider "aws" {
  region = "ap-south-1"  # Change this to your desired AWS region
}

# 1. Create VPC
resource "aws_vpc" "mumbaivpc" {
  cidr_block = "12.168.0.0/16"
  enable_dns_support = true
  enable_dns_hostnames = true
  tags = {
    Name = "mumbaivpc"
  }
}

# 2. Create Internet Gateway
resource "aws_internet_gateway" "mumbaiigw" {
  vpc_id = aws_vpc.mumbaivpc.id
  tags = {
    Name = "mumbaiigw"
  }
}

# 3. Create Subnets
resource "aws_subnet" "public_subnet" {
  vpc_id                  = aws_vpc.mumbaivpc.id
  cidr_block              = "192.168.1.0/24"
  availability_zone       = "ap-south-1a"  # Change this to your desired availability zone
  map_public_ip_on_launch = true
  tags = {
    Name = "public subnet"
  }
}

resource "aws_subnet" "private_subnet" {
  vpc_id                  = aws_vpc.mumbaivpc.id
  cidr_block              = "192.168.2.0/24"
  availability_zone       = "ap-south-1b"  # Change this to your desired availability zone
  tags = {
    Name = "private subnet"
  }
}

# 4. Create NAT Gateway
resource "aws_nat_gateway" "mumbaiNAT" {
  allocation_id = aws_instance.nat_instance[0].network_interface_ids[0]
  subnet_id     = aws_subnet.public_subnet.id
  tags = {
    Name = "mumbaiNAT"
  }
}

# 5. Create Route Tables
resource "aws_route_table" "public_route_table" {
  vpc_id = aws_vpc.mumbaivpc.id
  tags = {
    Name = "public RT"
  }
}

resource "aws_route_table" "private_route_table" {
  vpc_id = aws_vpc.mumbaivpc.id
  tags = {
    Name = "private RT"
  }
}

# 6. Configure Routes and Associations
resource "aws_route" "public_route" {
  route_table_id         = aws_route_table.public_route_table.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.mumbaiigw.id
}

resource "aws_route" "private_route" {
  route_table_id         = aws_route_table.private_route_table.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.mumbaiNAT.id
}

resource "aws_security_group" "myownmumbaisg" {
  name        = "myownmumbaisg"
  description = "myownmumbaisg"
  vpc_id      = aws_vpc.mumbaivpc.id
}

# 7. Configure Security Group Rules
resource "aws_security_group_rule" "ssh_rule" {
  security_group_id = aws_security_group.myownmumbaisg.id
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "http_rule" {
  security_group_id = aws_security_group.myownmumbaisg.id
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
}

# 8. Create Instances
resource "aws_instance" "public_instance" {
  ami                    = "ami-0c84181f02b974bc3"  # Use a proper AMI ID for your OS
  instance_type          = "t2.micro"
  subnet_id              = aws_subnet.public_subnet.id
  associate_public_ip_address = true
  vpc_security_group_ids = [aws_security_group.myownmumbaisg.id]
}

resource "aws_instance" "private_instance" {
  ami                    = "ami-0c84181f02b974bc3"  # Use a proper AMI ID for your OS
  instance_type          = "t2.micro"
  subnet_id              = aws_subnet.private_subnet.id
  associate_public_ip_address = false
  vpc_security_group_ids = [aws_security_group.myownmumbaisg.id]
