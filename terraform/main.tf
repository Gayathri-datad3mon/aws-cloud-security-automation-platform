# =====================================================
# AWS CLOUD SECURITY AUTOMATION PLATFORM
# =====================================================
# This Terraform file builds an end-to-end AWS security monitoring pipeline:
# IAM Event → CloudTrail → EventBridge → Lambda → SNS → Email Alert

# -----------------------------
# Phase 1 - Secure S3 Bucket
# -----------------------------

# Creates an S3 bucket to store CloudTrail audit logs
resource "aws_s3_bucket" "secure_bucket" {
  bucket = "gayathri-cloud-security-platform-2026" # Globally unique S3 bucket name
}

# Enables versioning to preserve previous versions of log files
resource "aws_s3_bucket_versioning" "versioning" {
  bucket = aws_s3_bucket.secure_bucket.id # Applies versioning to the secure S3 bucket

  versioning_configuration {
    status = "Enabled" # Keeps previous versions of objects for recovery and log integrity
  }
}

# Enables default server-side encryption for all objects in the bucket
resource "aws_s3_bucket_server_side_encryption_configuration" "encryption" {
  bucket = aws_s3_bucket.secure_bucket.id # Applies encryption to the secure S3 bucket

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256" # Uses AWS-managed AES-256 encryption for stored logs
    }
  }
}

# Blocks public access to protect CloudTrail logs from exposure
resource "aws_s3_bucket_public_access_block" "public_access" {
  bucket = aws_s3_bucket.secure_bucket.id # Applies public access settings to the secure bucket

  block_public_acls       = true # Blocks public ACLs
  ignore_public_acls      = true # Ignores any public ACLs if they exist
  block_public_policy     = true # Blocks public bucket policies
  restrict_public_buckets = true # Restricts public and cross-account access
}

# -----------------------------
# Phase 2 - CloudTrail Logging
# -----------------------------

# Gets the current AWS account ID dynamically
data "aws_caller_identity" "current" {}

# Deletes CloudTrail logs after 7 days to control storage cost
resource "aws_s3_bucket_lifecycle_configuration" "log_retention" {
  bucket = aws_s3_bucket.secure_bucket.id # Applies lifecycle rule to the log bucket

  rule {
    id     = "delete-cloudtrail-logs-after-7-days" # Name of the lifecycle rule
    status = "Enabled" # Enables this lifecycle rule

    filter {
      prefix = "AWSLogs/" # Applies only to CloudTrail log objects
    }

    expiration {
      days = 7 # Deletes current log objects after 7 days
    }

    noncurrent_version_expiration {
      noncurrent_days = 7 # Deletes older object versions after 7 days
    }
  }
}

# Allows CloudTrail to write audit logs into the S3 bucket
resource "aws_s3_bucket_policy" "cloudtrail_policy" {
  bucket = aws_s3_bucket.secure_bucket.id # Attaches policy to the secure bucket

  policy = jsonencode({
    Version = "2012-10-17" # IAM policy language version
    Statement = [
      {
        Sid    = "AWSCloudTrailAclCheck" # Statement name
        Effect = "Allow" # Allows the action below
        Principal = {
          Service = "cloudtrail.amazonaws.com" # Grants access to CloudTrail service
        }
        Action   = "s3:GetBucketAcl" # Lets CloudTrail check bucket ownership and ACL
        Resource = aws_s3_bucket.secure_bucket.arn # Applies permission to the bucket itself
      },
      {
        Sid    = "AWSCloudTrailWrite" # Statement name
        Effect = "Allow" # Allows the action below
        Principal = {
          Service = "cloudtrail.amazonaws.com" # Grants access to CloudTrail service
        }
        Action = "s3:PutObject" # Lets CloudTrail write log files to S3
        Resource = "${aws_s3_bucket.secure_bucket.arn}/AWSLogs/${data.aws_caller_identity.current.account_id}/*" # Log path for this AWS account

        Condition = {
          StringEquals = {
            "s3:x-amz-acl" = "bucket-owner-full-control" # Ensures bucket owner controls delivered logs
          }
        }
      }
    ]
  })
}

# Creates CloudTrail to record AWS API activity
resource "aws_cloudtrail" "security_trail" {
  name                          = "security-trail" # CloudTrail trail name
  s3_bucket_name                = aws_s3_bucket.secure_bucket.id # Stores logs in the secure S3 bucket
  include_global_service_events = true # Captures IAM global service events
  is_multi_region_trail         = true # Captures events across all AWS regions
  enable_logging                = true # Starts CloudTrail logging

  depends_on = [
    aws_s3_bucket_policy.cloudtrail_policy # Ensures bucket policy exists before CloudTrail starts logging
  ]
}

# -----------------------------
# Phase 3 - EventBridge + SNS
# -----------------------------

# Creates an SNS topic for security alert notifications
resource "aws_sns_topic" "security_alerts" {
  name = "security-alerts" # SNS topic name
}

# Subscribes email address to SNS topic
resource "aws_sns_topic_subscription" "email_alert" {
  topic_arn = aws_sns_topic.security_alerts.arn # Uses the security-alerts SNS topic
  protocol  = "email" # Sends alerts by email
  endpoint  = "gayathrinaidu1999@gmail.com" # Email address receiving alerts
}

# Creates EventBridge rule to detect critical IAM security events
resource "aws_cloudwatch_event_rule" "iam_user_created" {
  name        = "iam-security-events" # EventBridge rule name
  description = "Detect critical IAM changes" # Rule purpose

  event_pattern = jsonencode({
    source = [
      "aws.iam" # Matches IAM service events
    ]

    detail-type = [
      "AWS API Call via CloudTrail" # Matches CloudTrail API activity
    ]

    detail = {
      eventName = [
        "CreateUser",         # Detects new IAM user creation
        "DeleteUser",         # Detects IAM user deletion
        "CreateAccessKey",    # Detects access key creation
        "DeleteAccessKey",    # Detects access key deletion
        "AttachUserPolicy",   # Detects managed policy attachment
        "PutUserPolicy",      # Detects inline policy creation or update
        "CreateLoginProfile"  # Detects console password creation
      ]
    }
  })
}

# Direct EventBridge to SNS target is commented out because Lambda now formats alerts first
# resource "aws_cloudwatch_event_target" "send_to_sns" {
#   rule = aws_cloudwatch_event_rule.iam_user_created.name
#   arn  = aws_sns_topic.security_alerts.arn
# }

# Allows EventBridge to publish messages to SNS if direct SNS target is used later
resource "aws_sns_topic_policy" "allow_eventbridge" {
  arn = aws_sns_topic.security_alerts.arn # Applies policy to the SNS topic

  policy = jsonencode({
    Version = "2012-10-17" # IAM policy language version
    Statement = [
      {
        Sid    = "AllowEventBridgePublish" # Statement name
        Effect = "Allow" # Allows the action below

        Principal = {
          Service = "events.amazonaws.com" # Grants permission to EventBridge
        }

        Action   = "sns:Publish" # Allows EventBridge to publish messages
        Resource = aws_sns_topic.security_alerts.arn # SNS topic receiving messages
      }
    ]
  })
}

# -----------------------------
# Phase 4 - Lambda Automation
# -----------------------------

# Creates IAM role that Lambda will assume during execution
resource "aws_iam_role" "lambda_role" {
  name = "security-alert-lambda-role" # IAM role name for Lambda

  assume_role_policy = jsonencode({
    Version = "2012-10-17" # IAM policy language version
    Statement = [{
      Action = "sts:AssumeRole" # Allows role assumption
      Effect = "Allow" # Allows Lambda to assume this role
      Principal = {
        Service = "lambda.amazonaws.com" # Trusted service is Lambda
      }
    }]
  })
}

# Attaches AWS managed basic execution policy to Lambda role
resource "aws_iam_role_policy_attachment" "lambda_basic" {
  role       = aws_iam_role.lambda_role.name # Lambda IAM role
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole" # Allows Lambda to write CloudWatch logs
}

# Gives Lambda permission to publish formatted alerts to SNS
resource "aws_iam_role_policy" "lambda_sns_publish" {
  name = "lambda-sns-publish" # Inline IAM policy name
  role = aws_iam_role.lambda_role.id # Attach policy to Lambda role

  policy = jsonencode({
    Version = "2012-10-17" # IAM policy language version
    Statement = [{
      Effect = "Allow" # Allows the action below
      Action = [
        "sns:Publish" # Allows Lambda to publish alerts
      ]
      Resource = aws_sns_topic.security_alerts.arn # Restricts publish access to this SNS topic only
    }]
  })
}

# Deploys Lambda function that formats CloudTrail events into readable security alerts
resource "aws_lambda_function" "security_alert" {
  function_name = "security-alert-formatter" # Lambda function name

  filename         = "../lambda/security_alert.zip" # Local ZIP file containing Python code
  source_code_hash = filebase64sha256("../lambda/security_alert.zip") # Forces update when ZIP changes

  role    = aws_iam_role.lambda_role.arn # IAM role used by Lambda
  handler = "security_alert.lambda_handler" # Python file and function entry point
  runtime = "python3.12" # Python runtime version

  environment {
    variables = {
      SNS_TOPIC_ARN = aws_sns_topic.security_alerts.arn # Passes SNS topic ARN to Lambda code
    }
  }

  depends_on = [
    aws_iam_role_policy_attachment.lambda_basic, # Ensures CloudWatch log permissions exist first
    aws_iam_role_policy.lambda_sns_publish       # Ensures SNS publish permission exists first
  ]
}

# Connects EventBridge rule to Lambda function
resource "aws_cloudwatch_event_target" "lambda_target" {
  rule = aws_cloudwatch_event_rule.iam_user_created.name # EventBridge rule that detects IAM events
  arn  = aws_lambda_function.security_alert.arn # Lambda function invoked by EventBridge
}

# Allows EventBridge to invoke the Lambda function
resource "aws_lambda_permission" "allow_eventbridge" {
  statement_id  = "AllowExecutionFromEventBridge" # Unique permission statement ID
  action        = "lambda:InvokeFunction" # Allows Lambda invocation
  function_name = aws_lambda_function.security_alert.function_name # Lambda function being invoked
  principal     = "events.amazonaws.com" # EventBridge service principal
  source_arn    = aws_cloudwatch_event_rule.iam_user_created.arn # Restricts invocation to this EventBridge rule
}
