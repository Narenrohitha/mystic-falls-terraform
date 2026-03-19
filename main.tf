terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.primary_region
}

provider "aws" {
  alias  = "secondary"
  region = var.secondary_region
}

module "mystic_falls_vpc" {
  source             = "./modules/vpc"
  vpc_name           = "mystic-falls"
  cidr_block         = var.mystic_falls_cidr
  enable_flow_logs   = true
  flow_log_group_arn = module.logging.cloudwatch_log_group_arn
  flow_log_role_arn  = module.iam.flow_log_role_arn
  tags               = var.common_tags
}

module "clock_tower_vpc" {
  source           = "./modules/vpc"
  providers        = { aws = aws.secondary }
  vpc_name         = "clock-tower"
  cidr_block       = var.clock_tower_cidr
  enable_flow_logs = false
  tags             = var.common_tags
}

module "mystic_falls_subnets" {
  source = "./modules/subnets"
  vpc_id = module.mystic_falls_vpc.vpc_id
  igw_id = module.mystic_falls_vpc.igw_id

  public_subnets = [
    { cidr = "10.0.0.0/27", az = "${var.primary_region}a", name = "public-1a" },
    { cidr = "10.0.0.32/27", az = "${var.primary_region}b", name = "public-1b" },
  ]
  private_subnets = [
    { cidr = "10.0.0.64/27", az = "${var.primary_region}a", name = "private-1a" },
    { cidr = "10.0.0.96/27", az = "${var.primary_region}b", name = "private-1b" },
  ]
  db_subnets = [
    { cidr = "10.0.0.128/27", az = "${var.primary_region}a", name = "private-db-1a" },
    { cidr = "10.0.0.160/27", az = "${var.primary_region}b", name = "private-db-1b" },
  ]
  tags = var.common_tags
}

module "clock_tower_subnets" {
  source    = "./modules/subnets"
  providers = { aws = aws.secondary }
  vpc_id    = module.clock_tower_vpc.vpc_id
  igw_id    = module.clock_tower_vpc.igw_id

  public_subnets = [
    { cidr = "192.168.0.0/27", az = "${var.secondary_region}b", name = "public-ct" },
  ]
  private_subnets = [
    { cidr = "192.168.0.32/27", az = "${var.secondary_region}b", name = "private-ct" },
  ]
  db_subnets = []
  tags       = var.common_tags
}

module "vpc_peering" {
  source = "./modules/peering"

  requester_vpc_id          = module.mystic_falls_vpc.vpc_id
  accepter_vpc_id           = module.clock_tower_vpc.vpc_id
  requester_region          = var.primary_region
  accepter_region           = var.secondary_region
  requester_cidr            = var.mystic_falls_cidr
  accepter_cidr             = var.clock_tower_cidr
  requester_route_table_ids = module.mystic_falls_subnets.all_route_table_ids
  accepter_route_table_ids  = module.clock_tower_subnets.all_route_table_ids

  providers = {
    aws.requester = aws
    aws.accepter  = aws.secondary
  }
}

module "security_groups" {
  source            = "./modules/security_groups"
  mystic_falls_vpc  = module.mystic_falls_vpc.vpc_id
  clock_tower_vpc   = module.clock_tower_vpc.vpc_id
  mystic_falls_cidr = var.mystic_falls_cidr
  clock_tower_cidr  = var.clock_tower_cidr
  your_ip           = var.allowed_ssh_cidr
  tags              = var.common_tags

  providers = {
    aws           = aws
    aws.secondary = aws.secondary
  }
}

module "alb" {
  source            = "./modules/alb"
  name              = "mystic-falls-alb"
  vpc_id            = module.mystic_falls_vpc.vpc_id
  public_subnet_ids = module.mystic_falls_subnets.public_subnet_ids
  security_group_id = module.security_groups.alb_sg_id
  web_server_ids    = module.ec2.web_server_ids
  tags              = var.common_tags
}

module "waf" {
  source   = "./modules/waf"
  alb_arn  = module.alb.alb_arn
  waf_name = "mystic-falls-waf"
  tags     = var.common_tags
}

module "ec2" {
  source   = "./modules/ec2"
  key_name = var.key_pair_name
  ami_id   = var.ec2_ami_id

  bastion = {
    subnet_id         = module.mystic_falls_subnets.public_subnet_ids[0]
    security_group_id = module.security_groups.bastion_sg_id
  }

  web_servers = [
    {
      name              = "web-server-1"
      subnet_id         = module.mystic_falls_subnets.private_subnet_ids[0]
      security_group_id = module.security_groups.web_sg_id
    },
    {
      name              = "web-server-2"
      subnet_id         = module.mystic_falls_subnets.private_subnet_ids[1]
      security_group_id = module.security_groups.web_sg_id
    },
  ]
  tags = var.common_tags
}

module "clock_tower_ec2" {
  source    = "./modules/ec2"
  providers = { aws = aws.secondary }
  key_name  = var.key_pair_name
  ami_id    = var.ec2_ami_id_secondary

  bastion = null

  web_servers = [
    {
      name              = "ct-server-1"
      subnet_id         = module.clock_tower_subnets.public_subnet_ids[0]
      security_group_id = module.security_groups.ct_sg_id
    },
    {
      name              = "ct-server-2"
      subnet_id         = module.clock_tower_subnets.private_subnet_ids[0]
      security_group_id = module.security_groups.ct_sg_id
    },
  ]
  tags = var.common_tags
}

module "rds" {
  source            = "./modules/rds"
  identifier        = "mystic-falls-db"
  db_subnet_ids     = module.mystic_falls_subnets.db_subnet_ids
  security_group_id = module.security_groups.rds_sg_id
  db_name           = var.db_name
  db_username       = var.db_username
  db_password       = var.db_password
  tags              = var.common_tags
}

module "iam" {
  source   = "./modules/iam"
  iam_user = var.iam_user_name
  tags     = var.common_tags
}

module "logging" {
  source          = "./modules/logging"
  environment     = var.environment
  lambda_role_arn = module.iam.lambda_role_arn
  tags            = var.common_tags
}

module "dynamodb" {
  source     = "./modules/dynamodb"
  table_name = var.dynamodb_table_name
  tags       = var.common_tags
}

module "secrets" {
  source      = "./modules/secrets"
  db_username = var.db_username
  db_password = var.db_password
  tags        = var.common_tags
}