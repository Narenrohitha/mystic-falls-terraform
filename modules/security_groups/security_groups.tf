terraform {
  required_providers {
    aws = {
      source                = "hashicorp/aws"
      configuration_aliases = [aws, aws.secondary]
    }
  }
}

variable "mystic_falls_vpc" {
  type = string
}

variable "clock_tower_vpc" {
  type = string
}

variable "mystic_falls_cidr" {
  type = string
}

variable "clock_tower_cidr" {
  type = string
}

variable "your_ip" {
  type = string
}

variable "tags" {
  type    = map(string)
  default = {}
}

resource "aws_security_group" "alb" {
  name        = "alb-sg"
  description = "Allow HTTP and HTTPS from internet"
  vpc_id      = var.mystic_falls_vpc

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, { Name = "alb-sg" })
}

resource "aws_security_group" "bastion" {
  name        = "bastion-sg"
  description = "Allow SSH from admin IP only"
  vpc_id      = var.mystic_falls_vpc

  ingress {
    description = "SSH from admin"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.your_ip]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, { Name = "bastion-sg" })
}

resource "aws_security_group" "web" {
  name        = "web-sg"
  description = "Allow HTTP from ALB and SSH from Bastion"
  vpc_id      = var.mystic_falls_vpc

  ingress {
    description     = "HTTP from ALB"
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  ingress {
    description     = "SSH from Bastion"
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.bastion.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, { Name = "web-sg" })
}

resource "aws_security_group" "rds" {
  name        = "rds-sg"
  description = "Allow MySQL from web servers only"
  vpc_id      = var.mystic_falls_vpc

  ingress {
    description     = "MySQL from web servers"
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.web.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, { Name = "rds-sg" })
}

resource "aws_security_group" "clock_tower" {
  provider    = aws.secondary
  name        = "clock-tower-sg"
  description = "Allow traffic from Mystic Falls via peering"
  vpc_id      = var.clock_tower_vpc

  ingress {
    description = "SSH from Mystic Falls"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.mystic_falls_cidr]
  }

  ingress {
    description = "All traffic from peering"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [var.mystic_falls_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, { Name = "clock-tower-sg" })
}

output "alb_sg_id" {
  value = aws_security_group.alb.id
}

output "bastion_sg_id" {
  value = aws_security_group.bastion.id
}

output "web_sg_id" {
  value = aws_security_group.web.id
}

output "rds_sg_id" {
  value = aws_security_group.rds.id
}

output "ct_sg_id" {
  value = aws_security_group.clock_tower.id
}