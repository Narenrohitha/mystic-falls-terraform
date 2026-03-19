variable "primary_region" {
  description = "AWS region for Mystic Falls VPC"
  type        = string
  default     = "us-east-1"
}

variable "secondary_region" {
  description = "AWS region for Clock Tower VPC"
  type        = string
  default     = "us-east-2"
}

variable "mystic_falls_cidr" {
  description = "CIDR block for Mystic Falls VPC"
  type        = string
  default     = "10.0.0.0/24"
}

variable "clock_tower_cidr" {
  description = "CIDR block for Clock Tower VPC"
  type        = string
  default     = "192.168.0.0/24"
}

variable "environment" {
  description = "Deployment environment"
  type        = string
  default     = "prod"
}

variable "key_pair_name" {
  description = "Name of the EC2 key pair (must exist in both regions)"
  type        = string
}

variable "ec2_ami_id" {
  description = "AMI ID for us-east-1 EC2 instances"
  type        = string
  default     = "ami-0fc6cf99992956a4a"
}

variable "ec2_ami_id_secondary" {
  description = "AMI ID for us-east-2 EC2 instances"
  type        = string
  default     = "ami-075a156f1500285e1"
}

variable "allowed_ssh_cidr" {
  description = "Your IP address with /32 — allowed to SSH to Bastion"
  type        = string
}

variable "db_name" {
  description = "RDS database name"
  type        = string
  default     = "mysticfallsdb"
}

variable "db_username" {
  description = "RDS master username"
  type        = string
  sensitive   = true
}

variable "db_password" {
  description = "RDS master password"
  type        = string
  sensitive   = true
}

variable "iam_user_name" {
  description = "IAM user name to create"
  type        = string
  default     = "mystic-falls-user"
}

variable "dynamodb_table_name" {
  description = "DynamoDB table name"
  type        = string
  default     = "mystic-falls-table"
}

variable "common_tags" {
  description = "Tags applied to all resources"
  type        = map(string)
  default = {
    Project     = "mystic-falls"
    ManagedBy   = "terraform"
    Environment = "prod"
  }
}