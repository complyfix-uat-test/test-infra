# S3 Buckets with various violations
resource "aws_s3_bucket" "data" {
  for_each = var.s3_buckets

  bucket = each.value.name

  tags = merge(
    var.tags,
    {
      Name    = each.value.name
      Purpose = each.value.purpose
    }
  )
}

# Moved block for testing module tracing (renamed from aws_s3_bucket.data to phi_storage)
moved {
  from = aws_s3_bucket.phi_storage
  to   = aws_s3_bucket.data["phi_storage"]
}

# S3 Versioning (VIOLATION: Pattern 2 - if disabled)
resource "aws_s3_bucket_versioning" "data" {
  for_each = var.s3_buckets

  bucket = aws_s3_bucket.data[each.key].id

  versioning_configuration {
    status = each.value.versioning ? "Enabled" : "Suspended"
  }
}

# S3 Encryption (VIOLATION: Pattern 1 - if not enabled)
resource "aws_s3_bucket_server_side_encryption_configuration" "data" {
  for_each = {
    for k, v in var.s3_buckets : k => v if v.encryption
  }

  bucket = aws_s3_bucket.data[each.key].id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# S3 Public Access Block (VIOLATION: Pattern 3 - if public_read is true)
resource "aws_s3_bucket_public_access_block" "data" {
  for_each = {
    for k, v in var.s3_buckets : k => v if !v.public_read
  }

  bucket = aws_s3_bucket.data[each.key].id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# S3 Access Logging (VIOLATION: Pattern 4 - if not enabled)
resource "aws_s3_bucket_logging" "data" {
  for_each = {
    for k, v in var.s3_buckets : k => v if v.access_logging
  }

  bucket = aws_s3_bucket.data[each.key].id

  target_bucket = aws_s3_bucket.logs.id
  target_prefix = "logs/${each.key}/"
}

# S3 Bucket for logs
resource "aws_s3_bucket" "logs" {
  bucket = "medvault-s3-logs-${data.aws_caller_identity.current.account_id}"

  tags = merge(
    var.tags,
    {
      Name    = "medvault-s3-logs"
      Purpose = "S3 access logs"
    }
  )
}

# Logging bucket encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "logs" {
  bucket = aws_s3_bucket.logs.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Logging bucket versioning
resource "aws_s3_bucket_versioning" "logs" {
  bucket = aws_s3_bucket.logs.id

  versioning_configuration {
    status = "Enabled"
  }
}

# Logging bucket public access block
resource "aws_s3_bucket_public_access_block" "logs" {
  bucket = aws_s3_bucket.logs.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# RDS PostgreSQL Instance
resource "aws_db_subnet_group" "main" {
  name       = "${var.environment}-db-subnet-group"
  subnet_ids = var.private_subnets

  tags = merge(
    var.tags,
    {
      Name = "${var.environment}-db-subnet-group"
    }
  )
}

# VIOLATION: Pattern 7 - RDS not encrypted (no storage_encrypted)
# VIOLATION: Pattern 8 - RDS publicly accessible
# VIOLATION: Pattern 18 - RDS no backup
# VIOLATION: Pattern 19 - RDS no multi-AZ
resource "aws_db_instance" "main" {
  identifier            = "${var.environment}-medvault-db"
  engine                = "postgres"
  engine_version        = "15.3"
  instance_class        = "db.t3.medium"
  allocated_storage      = var.rds_allocated_storage
  storage_type          = "gp3"
  db_name               = "medvault"
  username              = "admin"
  password              = random_password.db_password.result
  db_subnet_group_name  = aws_db_subnet_group.main.name
  vpc_security_group_ids = [data.aws_security_group.rds.id]

  # VIOLATION: Pattern 7 - encryption not enabled
  storage_encrypted = false

  # VIOLATION: Pattern 8 - publicly accessible
  publicly_accessible = true

  # VIOLATION: Pattern 18 - no backup retention
  backup_retention_period = 0

  # VIOLATION: Pattern 19 - no multi-AZ
  multi_az = false

  skip_final_snapshot       = true
  copy_tags_to_snapshot     = true
  deletion_protection       = false
  delete_automated_backups  = true

  tags = merge(
    var.tags,
    {
      Name = "${var.environment}-medvault-db"
    }
  )
}

# RDS password (randomly generated)
resource "random_password" "db_password" {
  length  = 32
  special = true
}

# Data source to get RDS security group
data "aws_security_group" "rds" {
  filter {
    name   = "tag:Name"
    values = ["${var.environment}-rds-sg"]
  }
}

# DynamoDB Table
# VIOLATION: Pattern 26 - DynamoDB no encryption
resource "aws_dynamodb_table" "phi_metadata" {
  name           = "${var.environment}-phi-metadata"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "patient_id"
  range_key      = "timestamp"

  attribute {
    name = "patient_id"
    type = "S"
  }

  attribute {
    name = "timestamp"
    type = "N"
  }

  # VIOLATION: Pattern 26 - no encryption
  server_side_encryption {
    enabled = false
  }

  point_in_time_recovery_specification {
    point_in_time_recovery_enabled = false
  }

  ttl {
    attribute_name = "expires_at"
    enabled        = true
  }

  tags = merge(
    var.tags,
    {
      Name = "${var.environment}-phi-metadata"
    }
  )
}

# ElastiCache Redis Cluster
resource "aws_elasticache_subnet_group" "main" {
  name       = "${var.environment}-redis-subnet-group"
  subnet_ids = var.private_subnets

  tags = var.tags
}

resource "aws_elasticache_cluster" "redis" {
  cluster_id           = "${var.environment}-medvault-redis"
  engine               = "redis"
  node_type           = "cache.t3.micro"
  num_cache_nodes      = 1
  parameter_group_name = "default.redis7"
  engine_version       = "7.0"
  port                 = 6379

  subnet_group_name          = aws_elasticache_subnet_group.main.name
  security_group_ids         = [data.aws_security_group.elasticache.id]
  automatic_failover_enabled = false
  multi_az_enabled           = false

  at_rest_encryption_enabled = false
  transit_encryption_enabled = false

  log_delivery_configuration {
    destination      = aws_cloudwatch_log_group.redis_slow.name
    destination_type = "cloudwatch-logs"
    log_format       = "json"
    enabled          = true
  }

  tags = merge(
    var.tags,
    {
      Name = "${var.environment}-medvault-redis"
    }
  )
}

resource "aws_cloudwatch_log_group" "redis_slow" {
  name              = "/aws/elasticache/${var.environment}-redis-slowlog"
  retention_in_days = var.cloudwatch_log_retention

  tags = var.tags
}

# Data source to get ElastiCache security group
data "aws_security_group" "elasticache" {
  filter {
    name   = "tag:Name"
    values = ["${var.environment}-elasticache-sg"]
  }
}

# EBS Volume
# VIOLATION: Pattern 9 - EBS not encrypted
resource "aws_ebs_volume" "data" {
  availability_zone = data.aws_availability_zones.available.names[0]
  size              = 100
  encrypted         = false # VIOLATION: Pattern 9

  tags = merge(
    var.tags,
    {
      Name = "${var.environment}-ebs-data-volume"
    }
  )
}

# Data source for availability zones
data "aws_availability_zones" "available" {
  state = "available"
}

# Data source for caller identity
data "aws_caller_identity" "current" {}

# SNS Topic for audit logs (for backup/archival)
resource "aws_sns_topic" "audit" {
  name              = "${var.environment}-medvault-audit-logs"
  kms_master_key_id = "alias/aws/sns" # Minimal KMS usage

  tags = merge(
    var.tags,
    {
      Name = "${var.environment}-audit-topic"
    }
  )
}
