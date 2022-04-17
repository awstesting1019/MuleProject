provider "aws" {
  region = "us-east-1"
  shared_credentials_file = "/Users/anu/.aws/credentials"
  
}

resource "aws_vpc" "vpc2" {
  cidr_block       = "10.2.0.0/16"
  instance_tenancy = "default"

  tags = {
    Name = "VPC2"
  }

  enable_dns_hostnames = true
}

resource "aws_subnet" "public_subnet" {
  depends_on = [
    aws_vpc.vpc2,
  ]

  vpc_id     = aws_vpc.vpc2.id
  cidr_block = "10.2.0.0/24"

  availability_zone = "us-east-1a"

  tags = {
    Name = "vpc2-public-subnet"
  }

  map_public_ip_on_launch = true
}

resource "aws_subnet" "private_subnet" {
  depends_on = [
    aws_vpc.vpc2,
  ]

  vpc_id     = aws_vpc.vpc2.id
  cidr_block = "10.2.1.0/24"

  availability_zone = "us-east-1b"

  tags = {
    Name = "vpc2-private-subnet"
  }
}

resource "aws_internet_gateway" "internet_gateway" {
  depends_on = [
    aws_vpc.vpc2,
  ]

  vpc_id = aws_vpc.vpc2.id

  tags = {
    Name = "internet-gateway"
  }
}

resource "aws_route_table" "IG_route_table" {
  depends_on = [
    aws_vpc.vpc2,
    aws_internet_gateway.internet_gateway,
  ]

  vpc_id = aws_vpc.vpc2.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.internet_gateway.id
  }

  tags = {
    Name = "IG-route-table"
  }
}

resource "aws_route_table_association" "associate_routetable_to_public_subnet" {
  depends_on = [
    aws_subnet.public_subnet,
    aws_route_table.IG_route_table,
  ]
  subnet_id      = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.IG_route_table.id
}

resource "aws_eip" "elastic_ip" {
  vpc      = true
}

resource "aws_nat_gateway" "nat_gateway" {
  depends_on = [
    aws_subnet.public_subnet,
    aws_eip.elastic_ip,
  ]
  allocation_id = aws_eip.elastic_ip.id
  subnet_id     = aws_subnet.public_subnet.id

  tags = {
    Name = "vpc2-nat-gateway"
  }
}

resource "aws_route_table" "NAT_route_table" {
  depends_on = [
    aws_vpc.vpc2,
    aws_nat_gateway.nat_gateway,
  ]

  vpc_id = aws_vpc.vpc2.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.nat_gateway.id
  }

  tags = {
    Name = "vpc2-NAT-route-table"
  }
}

resource "aws_route_table_association" "associate_routetable_to_private_subnet" {
  depends_on = [
    aws_subnet.private_subnet,
    aws_route_table.NAT_route_table,
  ]
  subnet_id      = aws_subnet.private_subnet.id
  route_table_id = aws_route_table.NAT_route_table.id
}

resource "aws_security_group" "sg_bastion_host" {
  depends_on = [
    aws_vpc.vpc2,
  ]
  name        = "sg bastion host"
  description = "bastion host security group"
  vpc_id      = aws_vpc.vpc2.id

  ingress {
    description = "allow SSH"
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
}

resource "aws_instance" "bastion_host" {
  depends_on = [
    aws_security_group.sg_bastion_host,
  ]
  ami = "ami-04505e74c0741db8d"
  instance_type = "t2.micro"
  key_name = "tfproj"
  vpc_security_group_ids = [aws_security_group.sg_bastion_host.id]
  subnet_id = aws_subnet.public_subnet.id
  user_data = <<-EOF
                #!/bin/bash
                sudo apt update -y
                EOF
  tags = {
      Name = "bastion host"
  }
}

resource "aws_security_group" "sg_mysql" {
  depends_on = [
    aws_vpc.vpc2,
  ]
  name        = "sg mysql"
  description = "Allow mysql inbound traffic"
  vpc_id      = aws_vpc.vpc2.id

  ingress {
    description = "allow TCP"
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
  }

  ingress {
    description = "allow SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "mysql" {
  depends_on = [
    aws_security_group.sg_mysql,
    aws_nat_gateway.nat_gateway,
    aws_route_table_association.associate_routetable_to_private_subnet,
  ]
  ami = "ami-04505e74c0741db8d"
  instance_type = "t2.micro"
  key_name = "tfproj"
  vpc_security_group_ids = [aws_security_group.sg_mysql.id]
  subnet_id = aws_subnet.private_subnet.id
  user_data = file("configure_mysql.sh")
  tags = {
      Name = "mysql-instance"
  }
}


