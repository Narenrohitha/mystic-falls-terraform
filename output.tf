output "alb_dns_name" {
  description = "Paste this into your browser to test the app"
  value       = module.alb.alb_dns_name
}

output "bastion_public_ip" {
  description = "SSH jump host public IP"
  value       = module.ec2.bastion_public_ip
}

output "mystic_falls_vpc_id" {
  value = module.mystic_falls_vpc.vpc_id
}

output "clock_tower_vpc_id" {
  value = module.clock_tower_vpc.vpc_id
}

output "vpc_peering_id" {
  value = module.vpc_peering.peering_id
}

output "rds_primary_endpoint" {
  description = "RDS primary connection endpoint"
  value       = module.rds.primary_endpoint
  sensitive   = true
}

output "rds_replica_endpoint" {
  description = "RDS read replica connection endpoint"
  value       = module.rds.replica_endpoint
  sensitive   = true
}

output "cloudtrail_s3_bucket" {
  value = module.logging.cloudtrail_bucket_name
}

output "sns_topic_arn" {
  value = module.logging.sns_topic_arn
}

output "iam_user_arn" {
  value = module.iam.iam_user_arn
}

output "dynamodb_table_name" {
  value = module.dynamodb.table_name
}

output "secrets_manager_arn" {
  value     = module.secrets.secret_arn
  sensitive = true
}