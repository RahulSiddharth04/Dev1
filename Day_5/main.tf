terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.92.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

resource "aws_vpc" "myvpc" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "my-vpc"
  }
}

# Public Subnets
resource "aws_subnet" "pubsub1" {
  vpc_id            = aws_vpc.myvpc.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "us-east-1a"

  tags = {
    Name = "sn1"
  }
}

resource "aws_subnet" "pubsub2" {
  vpc_id            = aws_vpc.myvpc.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "us-east-1b"

  tags = {
    Name = "sn2"
  }
}

# Private Subnets
resource "aws_subnet" "prisub1" {
  vpc_id            = aws_vpc.myvpc.id
  cidr_block        = "10.0.3.0/24"
  availability_zone = "us-east-1a"

  tags = {
    Name = "sn3"
  }
}

resource "aws_subnet" "prisub2" {
  vpc_id            = aws_vpc.myvpc.id
  cidr_block        = "10.0.4.0/24"
  availability_zone = "us-east-1b"

  tags = {
    Name = "sn4"
  }
}

# Internet Gateway
resource "aws_internet_gateway" "tfigw" {
  vpc_id = aws_vpc.myvpc.id

  tags = {
    Name = "tfigw"
  }
}

# Public Route Table
resource "aws_route_table" "tfpubrt" {
  vpc_id = aws_vpc.myvpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.tfigw.id
  }

  tags = {
    Name = "tfpublicroute"
  }
}

# Route Table Associations for Public Subnets
resource "aws_route_table_association" "pubsn1" {
  subnet_id      = aws_subnet.pubsub1.id
  route_table_id = aws_route_table.tfpubrt.id
}

resource "aws_route_table_association" "pubsn2" {
  subnet_id      = aws_subnet.pubsub2.id
  route_table_id = aws_route_table.tfpubrt.id
}

# Elastic IP for NAT Gateway
resource "aws_eip" "tfeip" {
  domain = "vpc"
}

# NAT Gateway
resource "aws_nat_gateway" "tfnat" {
  allocation_id = aws_eip.tfeip.id
  subnet_id     = aws_subnet.pubsub2.id

  tags = {
    Name = "gw NAT"
  }
}

# Private Route Table
resource "aws_route_table" "tfprirt" {
  vpc_id = aws_vpc.myvpc.id

  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.tfnat.id
  }

  tags = {
    Name = "tfprivateroute"
  }
}

# Route Table Associations for Private Subnets
resource "aws_route_table_association" "prisn3" {
  subnet_id      = aws_subnet.prisub1.id
  route_table_id = aws_route_table.tfprirt.id
}

resource "aws_route_table_association" "prisn4" {
  subnet_id      = aws_subnet.prisub2.id
  route_table_id = aws_route_table.tfprirt.id
}

# Security Group
resource "aws_security_group" "allow_tfsg" {
  name        = "allow_tfsg"
  description = "Allow inbound traffic"
  vpc_id      = aws_vpc.myvpc.id

  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "TfsecurityGroup"
  }
}

# Public Instance
resource "aws_instance" "pub_ins" {
  ami                         = "ami-0fc5d935ebf8bc3bc"
  instance_type               = "t2.micro"
  subnet_id                   = aws_subnet.pubsub2.id
  vpc_security_group_ids      = [aws_security_group.allow_tfsg.id]
  key_name                    = "David"
  associate_public_ip_address = true

  tags = {
    Name = "PublicInstance"
  }
}

# Private Instance
resource "aws_instance" "pri_ins" {
  ami                    = "ami-0fc5d935ebf8bc3bc"
  instance_type          = "t2.micro"
  subnet_id              = aws_subnet.prisub1.id
  vpc_security_group_ids = [aws_security_group.allow_tfsg.id]
  key_name               = "David"

  tags = {
    Name = "PrivateInstance"
  }
}
