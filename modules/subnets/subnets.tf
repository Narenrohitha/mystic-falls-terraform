terraform {
  required_providers {
    aws = { source = "hashicorp/aws" }
  }
}

variable "vpc_id" {
  type = string
}

variable "igw_id" {
  type = string
}

variable "tags" {
  type    = map(string)
  default = {}
}

variable "public_subnets" {
  type = list(object({
    cidr = string
    az   = string
    name = string
  }))
  default = []
}

variable "private_subnets" {
  type = list(object({
    cidr = string
    az   = string
    name = string
  }))
  default = []
}

variable "db_subnets" {
  type = list(object({
    cidr = string
    az   = string
    name = string
  }))
  default = []
}

resource "aws_subnet" "public" {
  count                   = length(var.public_subnets)
  vpc_id                  = var.vpc_id
  cidr_block              = var.public_subnets[count.index].cidr
  availability_zone       = var.public_subnets[count.index].az
  map_public_ip_on_launch = true
  tags = merge(var.tags, {
    Name = var.public_subnets[count.index].name
    Tier = "public"
  })
}

resource "aws_route_table" "public" {
  vpc_id = var.vpc_id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = var.igw_id
  }
  tags = merge(var.tags, { Name = "public-rt" })
}

resource "aws_route_table_association" "public" {
  count          = length(aws_subnet.public)
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

resource "aws_eip" "nat" {
  count  = length(var.public_subnets) > 0 ? 1 : 0
  domain = "vpc"
  tags   = merge(var.tags, { Name = "nat-eip" })
}

resource "aws_nat_gateway" "this" {
  count         = length(var.public_subnets) > 0 ? 1 : 0
  allocation_id = aws_eip.nat[0].id
  subnet_id     = aws_subnet.public[0].id
  tags          = merge(var.tags, { Name = "nat-gw" })
}

resource "aws_subnet" "private" {
  count             = length(var.private_subnets)
  vpc_id            = var.vpc_id
  cidr_block        = var.private_subnets[count.index].cidr
  availability_zone = var.private_subnets[count.index].az
  tags = merge(var.tags, {
    Name = var.private_subnets[count.index].name
    Tier = "private"
  })
}

resource "aws_route_table" "private" {
  count  = length(var.private_subnets) > 0 ? 1 : 0
  vpc_id = var.vpc_id

  dynamic "route" {
    for_each = length(aws_nat_gateway.this) > 0 ? [1] : []
    content {
      cidr_block     = "0.0.0.0/0"
      nat_gateway_id = aws_nat_gateway.this[0].id
    }
  }

  tags = merge(var.tags, { Name = "private-rt" })
}

resource "aws_route_table_association" "private" {
  count          = length(aws_subnet.private)
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private[0].id
}

resource "aws_subnet" "db" {
  count             = length(var.db_subnets)
  vpc_id            = var.vpc_id
  cidr_block        = var.db_subnets[count.index].cidr
  availability_zone = var.db_subnets[count.index].az
  tags = merge(var.tags, {
    Name = var.db_subnets[count.index].name
    Tier = "db"
  })
}

resource "aws_route_table" "db" {
  count  = length(var.db_subnets) > 0 ? 1 : 0
  vpc_id = var.vpc_id
  tags   = merge(var.tags, { Name = "db-rt" })
}

resource "aws_route_table_association" "db" {
  count          = length(aws_subnet.db)
  subnet_id      = aws_subnet.db[count.index].id
  route_table_id = aws_route_table.db[0].id
}

resource "aws_db_subnet_group" "this" {
  count      = length(var.db_subnets) > 0 ? 1 : 0
  name       = "db-subnet-group"
  subnet_ids = aws_subnet.db[*].id
  tags       = merge(var.tags, { Name = "db-subnet-group" })
}

output "public_subnet_ids" {
  value = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  value = aws_subnet.private[*].id
}

output "db_subnet_ids" {
  value = aws_subnet.db[*].id
}

output "db_subnet_group_name" {
  value = length(aws_db_subnet_group.this) > 0 ? aws_db_subnet_group.this[0].name : ""
}

output "all_route_table_ids" {
  value = concat(
    [aws_route_table.public.id],
    aws_route_table.private[*].id,
    aws_route_table.db[*].id
  )
}