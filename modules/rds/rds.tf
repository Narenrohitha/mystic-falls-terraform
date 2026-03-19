terraform {
  required_providers {
    aws = { source = "hashicorp/aws" }
  }
}

variable "identifier" {
  type = string
}

variable "db_subnet_ids" {
  type = list(string)
}

variable "security_group_id" {
  type = string
}

variable "db_name" {
  type = string
}

variable "db_username" {
  type      = string
  sensitive = true
}

variable "db_password" {
  type      = string
  sensitive = true
}

variable "tags" {
  type    = map(string)
  default = {}
}

resource "aws_db_subnet_group" "this" {
  name       = "${var.identifier}-subnet-group"
  subnet_ids = var.db_subnet_ids
  tags       = merge(var.tags, { Name = "${var.identifier}-subnet-group" })
}

# Primary RDS instance
resource "aws_db_instance" "primary" {
  identifier            = "${var.identifier}-primary"
  engine                = "mysql"
  engine_version        = "8.0"
  instance_class        = "db.t3.micro"
  allocated_storage     = 20
  max_allocated_storage = 100
  storage_type          = "gp3"
  storage_encrypted     = true

  db_name  = var.db_name
  username = var.db_username
  password = var.db_password

  db_subnet_group_name   = aws_db_subnet_group.this.name
  vpc_security_group_ids = [var.security_group_id]

  multi_az                = false
  publicly_accessible     = false
  skip_final_snapshot     = true
  backup_retention_period = 1
  deletion_protection     = false

  tags = merge(var.tags, { Name = "${var.identifier}-primary", Role = "primary" })
}

# NOTE: Read replica is commented out because:
# 1. AWS free tier only covers 1 RDS instance (750 hrs/month)
# 2. Read replicas require backup_retention_period >= 1 on primary
# 3. Running 2 RDS instances will incur charges
# Uncomment below when you upgrade to a paid account

# resource "aws_db_instance" "replica" {
#   identifier             = "${var.identifier}-replica"
#   replicate_source_db    = aws_db_instance.primary.identifier
#   instance_class         = "db.t3.micro"
#   storage_encrypted      = true
#   publicly_accessible    = false
#   skip_final_snapshot    = true
#   vpc_security_group_ids = [var.security_group_id]
#   tags = merge(var.tags, { Name = "${var.identifier}-replica", Role = "replica" })
# }

output "primary_endpoint" {
  value = aws_db_instance.primary.endpoint
}

output "replica_endpoint" {
  value = "replica-disabled-on-free-tier"
}