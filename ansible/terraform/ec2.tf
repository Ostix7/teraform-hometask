terraform {
  required_version = ">= 1.2.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 4.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"]
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }
}

resource "aws_security_group" "main_sg" {
  name        = "my-sg-terraform"
  description = "Security Group for 2 instances"
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port = 5432
    to_port   = 5435
    protocol  = "tcp"
    self      = true
  }
  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
}

data "aws_key_pair" "hometask" {
  key_name = "hometask"
}

resource "aws_instance" "servers" {
  count                  = var.instance_count
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.instance_type
  key_name               = data.aws_key_pair.hometask.key_name
  vpc_security_group_ids = [aws_security_group.main_sg.id]

  user_data = <<-EOT
    #!/bin/bash

    echo "${var.lecturer_public_key}" >> /home/ubuntu/.ssh/authorized_keys
    chown ubuntu:ubuntu /home/ubuntu/.ssh/authorized_keys
    chmod 600 /home/ubuntu/.ssh/authorized_keys
  EOT




  tags = {
    Name = "Server-${count.index + 1}"
  }
}

resource "local_file" "ansible_inventory" {
  filename = "${path.module}/../ansible/inventory.ini"
  content  = <<EOF
[db_master]
server1 ansible_host=${aws_instance.servers[0].public_ip} ansible_user=ubuntu ansible_ssh_common_args='-o StrictHostKeyChecking=no' ansible_ssh_private_key_file='~/.ssh/hometask.pem'

[db_replica]
server2 ansible_host=${aws_instance.servers[1].public_ip} ansible_user=ubuntu ansible_ssh_common_args='-o StrictHostKeyChecking=no' ansible_ssh_private_key_file='~/.ssh/hometask.pem'
EOF
  depends_on = [aws_instance.servers]
}


