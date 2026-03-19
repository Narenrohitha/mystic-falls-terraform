terraform {
  required_providers {
    aws = { source = "hashicorp/aws" }
  }
}

variable "vpc_name" {
  type = string
}

variable "cidr_block" {
  type = string
}

variable "enable_flow_logs" {
  type    = bool
  default = false
}

variable "flow_log_group_arn" {
  type    = string
  default = ""
}

variable "flow_log_role_arn" {
  type    = string
  default = ""
}

variable "tags" {
  type    = map(string)
  default = {}
}

resource "aws_vpc" "this" {
  cidr_block           = var.cidr_block
  enable_dns_hostnames = true
  enable_dns_support   = true
  tags                 = merge(var.tags, { Name = var.vpc_name })
}

resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id
  tags   = merge(var.tags, { Name = "${var.vpc_name}-igw" })
}

resource "aws_flow_log" "this" {
  count                = var.enable_flow_logs ? 1 : 0
  iam_role_arn         = var.flow_log_role_arn
  log_destination      = var.flow_log_group_arn
  log_destination_type = "cloud-watch-logs"
  traffic_type         = "ALL"
  vpc_id               = aws_vpc.this.id
  tags                 = merge(var.tags, { Name = "${var.vpc_name}-flow-logs" })
}

output "vpc_id" {
  value = aws_vpc.this.id
}

output "igw_id" {
  value = aws_internet_gateway.this.id
}