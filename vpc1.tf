provider "aws" {
  region = "us-east-1"
  shared_credentials_file = "/Users/anu/.aws/credentials"
  
}

resource "aws_vpc" "vpc1" {
  cidr_block       = "10.1.0.0/16"
  instance_tenancy = "default"

  tags = {
    Name = "VPC1"
  }
}

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.vpc1.id

  tags = {
    Name = "VPC1-gw"
  }
}

resource "aws_route_table" "rt" {
  vpc_id = aws_vpc.vpc1.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }

  route {
    ipv6_cidr_block        = "::/0"
    gateway_id = aws_internet_gateway.gw.id
  }

  tags = {
    Name = "VPC1-rt"
  }
}

resource "aws_subnet" "subnet-1" {
  vpc_id     = aws_vpc.vpc1.id
  cidr_block = "10.1.1.0/24"
  availability_zone = "us-east-1a"

  tags = {
    Name = "VPC1-subnet"
  }
}

resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.subnet-1.id
  route_table_id = aws_route_table.rt.id
}

resource "aws_security_group" "vpc1-sg" {
  name        = "vpc1-sg"
  description = "Allow Web inbound traffic"
  vpc_id      = aws_vpc.vpc1.id

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
    Name = "vpc1_sg"
  }
}

resource "aws_network_interface" "linux-ec2" {
  subnet_id       = aws_subnet.subnet-1.id
  private_ips     = ["10.1.1.50"]
  security_groups = [aws_security_group.vpc1-sg.id]

}
resource "aws_eip" "one" {
  vpc                       = true
  network_interface         = aws_network_interface.linux-ec2.id
  associate_with_private_ip = "10.1.1.50"
  depends_on                = [aws_internet_gateway.gw]
}

output "server_public_ip" {
  value = aws_eip.one.public_ip
}

resource "aws_instance" "linux-ec2" {
  ami               = "ami-04505e74c0741db8d"
  instance_type     = "t2.micro"
  availability_zone = "us-east-1a"
  key_name          = "tfproj"

  network_interface {
    device_index         = 0
    network_interface_id = aws_network_interface.linux-ec2.id
  }

  user_data = <<-EOF
                #!/bin/bash
                sudo apt update -y
                EOF
  tags = {
    Name = "linux-ec2"
  }
}

output "server_private_ip" {
  value = aws_instance.linux-ec2.private_ip

}

output "server_id" {
  value = aws_instance.linux-ec2.id
}


