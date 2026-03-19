terraform {
  required_providers {
    aws = { source = "hashicorp/aws" }
  }
}

variable "key_name" {
  type = string
}

variable "ami_id" {
  type = string
}

variable "tags" {
  type    = map(string)
  default = {}
}

variable "bastion" {
  type = object({
    subnet_id         = string
    security_group_id = string
  })
  default = null
}

variable "web_servers" {
  type = list(object({
    name              = string
    subnet_id         = string
    security_group_id = string
  }))
  default = []
}

locals {
  user_data = <<-EOF
    #!/bin/bash
    yum update -y
    yum install -y httpd
    systemctl start httpd
    systemctl enable httpd
    echo "<h1>Hello from $(hostname -f)</h1>" > /var/www/html/index.html
  EOF
}

resource "aws_instance" "bastion" {
  count                       = var.bastion != null ? 1 : 0
  ami                         = var.ami_id
  instance_type               = "t3.micro"
  key_name                    = var.key_name
  subnet_id                   = var.bastion.subnet_id
  vpc_security_group_ids      = [var.bastion.security_group_id]
  associate_public_ip_address = true

  tags = merge(var.tags, { Name = "bastion-host", Role = "bastion" })
}

resource "aws_instance" "web" {
  count                  = length(var.web_servers)
  ami                    = var.ami_id
  instance_type          = "t3.micro"
  key_name               = var.key_name
  subnet_id              = var.web_servers[count.index].subnet_id
  vpc_security_group_ids = [var.web_servers[count.index].security_group_id]
  user_data              = base64encode(local.user_data)

  tags = merge(var.tags, {
    Name = var.web_servers[count.index].name
    Role = "web"
  })
}

output "bastion_public_ip" {
  value = length(aws_instance.bastion) > 0 ? aws_instance.bastion[0].public_ip : ""
}

output "web_server_ids" {
  value = aws_instance.web[*].id
}