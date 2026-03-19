terraform {
  required_providers {
    aws = { source = "hashicorp/aws" }
  }
}

variable "environment" {
  type = string
}

variable "lambda_role_arn" {
  type = string
}

variable "tags" {
  type    = map(string)
  default = {}
}

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

resource "aws_cloudwatch_log_group" "flow_logs" {
  name              = "/aws/vpc/flow-logs"
  retention_in_days = 30
  tags              = merge(var.tags, { Name = "vpc-flow-logs" })
}

resource "aws_s3_bucket" "cloudtrail" {
  bucket        = "cloudtrail-logs-${data.aws_caller_identity.current.account_id}-${var.environment}"
  force_destroy = true
  tags          = merge(var.tags, { Name = "cloudtrail-bucket" })
}

resource "aws_s3_bucket_versioning" "cloudtrail" {
  bucket = aws_s3_bucket.cloudtrail.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "cloudtrail" {
  bucket = aws_s3_bucket.cloudtrail.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "cloudtrail" {
  bucket                  = aws_s3_bucket.cloudtrail.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

data "aws_iam_policy_document" "cloudtrail_bucket" {
  statement {
    sid    = "AWSCloudTrailAclCheck"
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["cloudtrail.amazonaws.com"]
    }
    actions   = ["s3:GetBucketAcl"]
    resources = [aws_s3_bucket.cloudtrail.arn]
  }
  statement {
    sid    = "AWSCloudTrailWrite"
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["cloudtrail.amazonaws.com"]
    }
    actions   = ["s3:PutObject"]
    resources = ["${aws_s3_bucket.cloudtrail.arn}/AWSLogs/${data.aws_caller_identity.current.account_id}/*"]
    condition {
      test     = "StringEquals"
      variable = "s3:x-amz-acl"
      values   = ["bucket-owner-full-control"]
    }
  }
}

resource "aws_s3_bucket_policy" "cloudtrail" {
  bucket     = aws_s3_bucket.cloudtrail.id
  policy     = data.aws_iam_policy_document.cloudtrail_bucket.json
  depends_on = [aws_s3_bucket_public_access_block.cloudtrail]
}

resource "aws_sns_topic" "alerts" {
  name = "cloudtrail-alerts-${var.environment}"
  tags = merge(var.tags, { Name = "cloudtrail-alerts" })
}

resource "aws_sns_topic_subscription" "email" {
  topic_arn = aws_sns_topic.alerts.arn
  protocol  = "email"
  endpoint  = "alerts@example.com"
}

data "archive_file" "lambda_zip" {
  type        = "zip"
  output_path = "${path.module}/lambda_function.zip"

  source {
    content  = <<-PYEOF
import json
import boto3
import os

sns = boto3.client('sns')

def handler(event, context):
    print(json.dumps(event))
    for record in event.get('Records', []):
        bucket  = record['s3']['bucket']['name']
        key     = record['s3']['object']['key']
        message = f"New CloudTrail log: s3://{bucket}/{key}"
        sns.publish(
            TopicArn=os.environ['SNS_TOPIC_ARN'],
            Subject="CloudTrail Log Delivered",
            Message=message,
        )
    return {'statusCode': 200}
    PYEOF
    filename = "lambda_function.py"
  }
}

resource "aws_lambda_function" "cloudtrail_processor" {
  filename         = data.archive_file.lambda_zip.output_path
  function_name    = "cloudtrail-log-processor"
  role             = var.lambda_role_arn
  handler          = "lambda_function.handler"
  runtime          = "python3.12"
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256
  timeout          = 30

  environment {
    variables = {
      SNS_TOPIC_ARN = aws_sns_topic.alerts.arn
    }
  }

  tags = merge(var.tags, { Name = "cloudtrail-processor" })
}

resource "aws_lambda_permission" "s3" {
  statement_id  = "AllowS3Invoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.cloudtrail_processor.function_name
  principal     = "s3.amazonaws.com"
  source_arn    = aws_s3_bucket.cloudtrail.arn
}

resource "aws_s3_bucket_notification" "cloudtrail" {
  bucket = aws_s3_bucket.cloudtrail.id

  lambda_function {
    lambda_function_arn = aws_lambda_function.cloudtrail_processor.arn
    events              = ["s3:ObjectCreated:*"]
    filter_prefix       = "AWSLogs/"
  }

  depends_on = [aws_lambda_permission.s3]
}

resource "aws_cloudwatch_log_group" "cloudtrail" {
  name              = "/aws/cloudtrail/mystic-falls"
  retention_in_days = 90
  tags              = merge(var.tags, { Name = "cloudtrail-log-group" })
}

# IAM role for CloudTrail to write to CloudWatch
data "aws_iam_policy_document" "cloudtrail_cw_assume" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["cloudtrail.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "cloudtrail_cw" {
  name               = "cloudtrail-cw-logs-role"
  assume_role_policy = data.aws_iam_policy_document.cloudtrail_cw_assume.json
  tags               = var.tags
}

resource "aws_iam_role_policy" "cloudtrail_cw" {
  name = "cloudtrail-cw-logs-policy"
  role = aws_iam_role.cloudtrail_cw.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ]
      Resource = "${aws_cloudwatch_log_group.cloudtrail.arn}:*"
    }]
  })
}

resource "aws_cloudtrail" "this" {
  name                          = "mystic-falls-trail"
  s3_bucket_name                = aws_s3_bucket.cloudtrail.id
  include_global_service_events = true
  is_multi_region_trail         = true
  enable_log_file_validation    = true
  cloud_watch_logs_group_arn    = "${aws_cloudwatch_log_group.cloudtrail.arn}:*"
  cloud_watch_logs_role_arn     = aws_iam_role.cloudtrail_cw.arn

  event_selector {
    read_write_type           = "All"
    include_management_events = true

    data_resource {
      type   = "AWS::S3::Object"
      values = ["arn:aws:s3:::"]
    }
  }

  tags = merge(var.tags, { Name = "mystic-falls-trail" })

  depends_on = [
    aws_s3_bucket_policy.cloudtrail,
    aws_iam_role_policy.cloudtrail_cw
  ]
}

output "cloudwatch_log_group_arn" {
  value = aws_cloudwatch_log_group.flow_logs.arn
}

output "cloudtrail_bucket_name" {
  value = aws_s3_bucket.cloudtrail.id
}

output "sns_topic_arn" {
  value = aws_sns_topic.alerts.arn
}

output "lambda_function_name" {
  value = aws_lambda_function.cloudtrail_processor.function_name
}