provider "aws" {
  access_key = "AKIAVYSNLTQT47EI4LHI"
  secret_key = "kpxmAVSos5EBzWapGQpPFqvsVoVstiLxmD4dHw8o"
  region     = "us-east-1"
}

resource "aws_instance" "example" {
  ami           = "ami-03ededff12e34e59e"
  instance_type = "t2.micro"
  vpc_security_group_ids = ["${aws_security_group.allow_ssh.id}"]
}
