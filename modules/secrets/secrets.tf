terraform {
  required_providers {
    aws = { source = "hashicorp/aws" }
  }
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

resource "aws_secretsmanager_secret" "db_credentials" {
  name                    = "mystic-falls/db-credentials"
  recovery_window_in_days = 7
  tags                    = merge(var.tags, { Name = "db-credentials" })
}

resource "aws_secretsmanager_secret_version" "db_credentials" {
  secret_id = aws_secretsmanager_secret.db_credentials.id
  secret_string = jsonencode({
    username = var.db_username
    password = var.db_password
  })
}

output "secret_arn" {
  value = aws_secretsmanager_secret.db_credentials.arn
}

output "secret_name" {
  value = aws_secretsmanager_secret.db_credentials.name
}