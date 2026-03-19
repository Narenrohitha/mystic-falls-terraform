terraform {
  required_providers {
    aws = {
      source                = "hashicorp/aws"
      configuration_aliases = [aws.requester, aws.accepter]
    }
  }
}

variable "requester_vpc_id" {
  type = string
}

variable "accepter_vpc_id" {
  type = string
}

variable "requester_region" {
  type = string
}

variable "accepter_region" {
  type = string
}

variable "requester_cidr" {
  type = string
}

variable "accepter_cidr" {
  type = string
}

variable "requester_route_table_ids" {
  type = list(string)
}

variable "accepter_route_table_ids" {
  type = list(string)
}

resource "aws_vpc_peering_connection" "this" {
  provider    = aws.requester
  vpc_id      = var.requester_vpc_id
  peer_vpc_id = var.accepter_vpc_id
  peer_region = var.accepter_region
  auto_accept = false
  tags        = { Name = "mystic-falls-to-clock-tower" }
}

resource "aws_vpc_peering_connection_accepter" "this" {
  provider                  = aws.accepter
  vpc_peering_connection_id = aws_vpc_peering_connection.this.id
  auto_accept               = true
  tags                      = { Name = "clock-tower-to-mystic-falls" }
}

resource "aws_route" "requester_to_accepter" {
  provider                  = aws.requester
  count                     = length(var.requester_route_table_ids)
  route_table_id            = var.requester_route_table_ids[count.index]
  destination_cidr_block    = var.accepter_cidr
  vpc_peering_connection_id = aws_vpc_peering_connection.this.id
}

resource "aws_route" "accepter_to_requester" {
  provider                  = aws.accepter
  count                     = length(var.accepter_route_table_ids)
  route_table_id            = var.accepter_route_table_ids[count.index]
  destination_cidr_block    = var.requester_cidr
  vpc_peering_connection_id = aws_vpc_peering_connection.this.id
}

output "peering_id" {
  value = aws_vpc_peering_connection.this.id
}