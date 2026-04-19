# CloudWatch Log Groups for various services
# VIOLATION: Pattern 20 - CloudWatch no retention (retention_in_days = 0 or absent)
resource "aws_cloudwatch_log_group" "eks_cluster" {
  name              = "/aws/eks/${var.cluster_name}/cluster"
  retention_in_days = 0 # VIOLATION: Pattern 20 - No retention

  tags = var.tags
}

resource "aws_cloudwatch_log_group" "eks_api" {
  name              = "/aws/eks/${var.cluster_name}/api"
  retention_in_days = var.log_retention_days

  tags = var.tags
}

resource "aws_cloudwatch_log_group" "eks_audit" {
  name              = "/aws/eks/${var.cluster_name}/audit"
  retention_in_days = var.log_retention_days

  tags = var.tags
}

resource "aws_cloudwatch_log_group" "rds_logs" {
  name              = "/aws/rds/${var.environment}-medvault-db"
  retention_in_days = 3 # VIOLATION: Pattern 20 - Too short retention

  tags = var.tags
}

# SNS Topic for Alarms
# VIOLATION: Pattern 30 - SNS not encrypted (no kms_master_key_id)
resource "aws_sns_topic" "alarms" {
  name              = "${var.environment}-medvault-alarms"
  # VIOLATION: Pattern 30 - No KMS encryption specified
  display_name      = "MedVault Infrastructure Alarms"

  tags = merge(
    var.tags,
    {
      Name = "${var.environment}-alarms"
    }
  )
}

# Optional: SNS topic with encryption (when enabled)
resource "aws_sns_topic" "secure_alarms" {
  count             = var.enable_kms_encryption ? 1 : 0
  name              = "${var.environment}-medvault-secure-alarms"
  kms_master_key_id = var.kms_key_id

  tags = merge(
    var.tags,
    {
      Name = "${var.environment}-secure-alarms"
    }
  )
}

# SNS Topic Subscription (for email alerts)
resource "aws_sns_topic_subscription" "alarms_email" {
  topic_arn = aws_sns_topic.alarms.arn
  protocol  = "email"
  endpoint  = "ops@medvault.local" # Placeholder

  depends_on = [aws_sns_topic.alarms]
}

# CloudWatch Alarms for RDS
resource "aws_cloudwatch_metric_alarm" "rds_cpu" {
  alarm_name          = "${var.environment}-rds-cpu-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/RDS"
  period              = 300
  statistic           = "Average"
  threshold           = 80
  alarm_description   = "Alert when RDS CPU is high"
  alarm_actions       = [aws_sns_topic.alarms.arn]
  treat_missing_data  = "notBreaching"

  dimensions = {
    DBInstanceIdentifier = var.rds_instance_id
  }

  tags = var.tags
}

resource "aws_cloudwatch_metric_alarm" "rds_storage" {
  alarm_name          = "${var.environment}-rds-storage-low"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 1
  metric_name         = "FreeStorageSpace"
  namespace           = "AWS/RDS"
  period              = 300
  statistic           = "Average"
  threshold           = 10737418240 # 10 GB in bytes
  alarm_description   = "Alert when RDS storage is low"
  alarm_actions       = [aws_sns_topic.alarms.arn]
  treat_missing_data  = "notBreaching"

  dimensions = {
    DBInstanceIdentifier = var.rds_instance_id
  }

  tags = var.tags
}

resource "aws_cloudwatch_metric_alarm" "rds_connections" {
  alarm_name          = "${var.environment}-rds-connections-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "DatabaseConnections"
  namespace           = "AWS/RDS"
  period              = 300
  statistic           = "Average"
  threshold           = 100
  alarm_description   = "Alert when RDS connections are high"
  alarm_actions       = [aws_sns_topic.alarms.arn]
  treat_missing_data  = "notBreaching"

  dimensions = {
    DBInstanceIdentifier = var.rds_instance_id
  }

  tags = var.tags
}

# CloudWatch Dashboard
resource "aws_cloudwatch_dashboard" "main" {
  dashboard_name = "${var.environment}-medvault-dashboard"

  dashboard_body = jsonencode({
    widgets = [
      {
        type = "metric"
        properties = {
          metrics = [
            ["AWS/RDS", "CPUUtilization", { stat = "Average" }],
            [".", "DatabaseConnections", { stat = "Sum" }],
            ["AWS/EKS", "cluster_node_count", { stat = "Average" }]
          ]
          period = 300
          stat   = "Average"
          region = data.aws_region.current.name
          title  = "Infrastructure Health"
        }
      },
      {
        type = "log"
        properties = {
          query   = "fields @timestamp, @message | stats count() by bin(5m)"
          region  = data.aws_region.current.name
          title   = "Log Events Over Time"
        }
      }
    ]
  })

  tags = var.tags
}

# Lambda Custom Metric for monitoring
resource "aws_cloudwatch_metric_alarm" "custom_metric" {
  alarm_name          = "${var.environment}-custom-compliance-check"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  metric_name         = "ComplianceViolations"
  namespace           = "MedVault/Compliance"
  period              = 3600
  statistic           = "Sum"
  threshold           = 1
  alarm_description   = "Alert on compliance violations"
  alarm_actions       = [aws_sns_topic.alarms.arn]
  treat_missing_data  = "notBreaching"

  tags = var.tags
}

# Log Metric Filter (example: count errors)
resource "aws_cloudwatch_log_metric_filter" "errors" {
  name           = "${var.environment}-error-count"
  log_group_name = aws_cloudwatch_log_group.rds_logs.name
  filter_pattern = "[time, request_id, event_type = ERROR, ...]"

  metric_transformation {
    name      = "ErrorCount"
    namespace = "MedVault/Application"
    value     = "1"
  }
}

data "aws_region" "current" {}
