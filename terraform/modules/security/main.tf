# KMS Key for encryption
resource "aws_kms_key" "main" {
  description             = "KMS key for MedVault infrastructure encryption"
  deletion_window_in_days = 10
  enable_key_rotation     = true

  tags = merge(
    var.tags,
    {
      Name = "${var.environment}-medvault-key"
    }
  )
}

resource "aws_kms_alias" "main" {
  name          = "alias/${var.environment}-medvault"
  target_key_id = aws_kms_key.main.key_id
}

# CloudTrail for audit logging
# VIOLATION: Pattern 10 - CloudTrail disabled (if enable_cloudtrail is false)
resource "aws_cloudtrail" "main" {
  count                      = var.enable_cloudtrail ? 1 : 0
  name                       = "${var.environment}-medvault-trail"
  s3_bucket_name            = var.s3_bucket_name
  include_global_service_events = true
  is_multi_region_trail     = true
  enable_log_file_validation = true

  depends_on = [aws_s3_bucket_policy.cloudtrail[0]]

  tags = var.tags
}

# S3 bucket policy for CloudTrail
resource "aws_s3_bucket_policy" "cloudtrail" {
  count  = var.enable_cloudtrail ? 1 : 0
  bucket = var.s3_bucket_name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AWSCloudTrailAclCheck"
        Effect = "Allow"
        Principal = {
          Service = "cloudtrail.amazonaws.com"
        }
        Action   = "s3:GetBucketAcl"
        Resource = "arn:aws:s3:::${var.s3_bucket_name}"
      },
      {
        Sid    = "AWSCloudTrailWrite"
        Effect = "Allow"
        Principal = {
          Service = "cloudtrail.amazonaws.com"
        }
        Action   = "s3:PutObject"
        Resource = "arn:aws:s3:::${var.s3_bucket_name}/*"
        Condition = {
          StringEquals = {
            "s3:x-amz-acl" = "bucket-owner-full-control"
          }
        }
      }
    ]
  })
}

# IAM Role for EKS pod service accounts
resource "aws_iam_role" "eks_sa_role" {
  name = "${var.cluster_name}-sa-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRoleWithWebIdentity"
        Effect = "Allow"
        Principal = {
          Federated = "arn:aws:iam::${var.account_id}:oidc-provider/${replace(var.cluster_oidc_url, "https://", "")}"
        }
        Condition = {
          StringEquals = {
            "${replace(var.cluster_oidc_url, "https://", "")}:sub" = "system:serviceaccount:default:*"
          }
        }
      }
    ]
  })

  tags = var.tags
}

# VIOLATION: Pattern 11 - IAM policy too permissive (wildcard actions and resources)
resource "aws_iam_role_policy" "eks_sa_policy" {
  name = "${var.cluster_name}-sa-policy"
  role = aws_iam_role.eks_sa_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:*",
          "ec2:*",
          "elasticache:*"
        ]
        Resource = "*" # VIOLATION: Pattern 11 - wildcard resource
      },
      {
        Effect = "Allow"
        Action = "*" # VIOLATION: Pattern 11 - wildcard actions
        Resource = "arn:aws:s3:::medvault-*"
      }
    ]
  })
}

# Lambda execution role
resource "aws_iam_role" "lambda_execution" {
  name = "${var.cluster_name}-lambda-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })

  tags = var.tags
}

# Lambda basic execution policy
resource "aws_iam_role_policy_attachment" "lambda_basic" {
  role       = aws_iam_role.lambda_execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# Root account (example of anti-pattern - VIOLATION: Pattern 23 - Root account access keys)
# This simulates detecting existing root access keys in the account
# In reality, this would be detected by Checkov policy checking IAM credential report
resource "aws_iam_account_password_policy" "root_password" {
  minimum_password_length        = 14
  require_lowercase_characters   = true
  require_numbers                = true
  require_uppercase_characters   = true
  require_symbols                = true
  allow_users_to_change_password = true
  expire_passwords               = false
  max_password_age               = 0
  password_reuse_prevention      = 24
  hard_expiry                    = false

  # VIOLATION: Pattern 22 - MFA not enforced for root account
  # In real scenario, root account should be protected with MFA
  # This policy doesn't enforce it
}

# Placeholder for IAM user (example of bad practice)
# VIOLATION: Pattern 22 - User without MFA
resource "aws_iam_user" "legacy_user" {
  name = "${var.environment}-legacy-admin"

  tags = merge(
    var.tags,
    {
      Name = "Legacy admin user - TODO: Enable MFA"
    }
  )
}

resource "aws_iam_user_policy" "legacy_user" {
  name = "${var.environment}-legacy-admin-policy"
  user = aws_iam_user.legacy_user.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = "sts:AssumeRole"
        Resource = aws_iam_role.eks_sa_role.arn
      }
    ]
  })
}

# KMS key policy (allows usage)
resource "aws_kms_key_policy" "main" {
  key_id = aws_kms_key.main.id

  policy = jsonencode({
    Version = "2012-10-17"
    Id      = "kms-key-policy-1"
    Statement = [
      {
        Sid    = "Enable IAM policies"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${var.account_id}:root"
        }
        Action   = "kms:*"
        Resource = "*"
      },
      {
        Sid    = "Allow services to use the key"
        Effect = "Allow"
        Principal = {
          Service = [
            "s3.amazonaws.com",
            "logs.amazonaws.com",
            "sns.amazonaws.com"
          ]
        }
        Action = [
          "kms:Decrypt",
          "kms:GenerateDataKey"
        ]
        Resource = "*"
      }
    ]
  })
}

# VPC Endpoint for S3 (example of infrastructure hardening)
resource "aws_vpc_endpoint" "s3" {
  count           = 0 # Disabled for MVP test corpus
  vpc_id          = "vpc-xxxxx"
  service_name    = "com.amazonaws.${data.aws_region.current.name}.s3"
  route_table_ids = []

  tags = var.tags
}

data "aws_region" "current" {}
