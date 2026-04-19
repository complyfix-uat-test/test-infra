output "s3_bucket_ids" {
  description = "S3 bucket IDs"
  value       = { for k, v in aws_s3_bucket.data : k => v.id }
}

output "s3_bucket_arns" {
  description = "S3 bucket ARNs"
  value       = { for k, v in aws_s3_bucket.data : k => v.arn }
}

output "logs_bucket_id" {
  description = "Logs S3 bucket ID"
  value       = aws_s3_bucket.logs.id
}

output "audit_bucket_name" {
  description = "Audit bucket name for CloudTrail"
  value       = aws_s3_bucket.logs.id
}

output "rds_endpoint" {
  description = "RDS database endpoint"
  value       = aws_db_instance.main.endpoint
  sensitive   = true
}

output "rds_instance_id" {
  description = "RDS instance ID"
  value       = aws_db_instance.main.id
}

output "rds_arn" {
  description = "RDS instance ARN"
  value       = aws_db_instance.main.arn
}

output "dynamodb_table_name" {
  description = "DynamoDB table name"
  value       = aws_dynamodb_table.phi_metadata.name
}

output "dynamodb_table_arn" {
  description = "DynamoDB table ARN"
  value       = aws_dynamodb_table.phi_metadata.arn
}

output "elasticache_endpoint" {
  description = "ElastiCache Redis endpoint"
  value       = aws_elasticache_cluster.redis.cache_nodes[0].address
  sensitive   = true
}

output "elasticache_cluster_id" {
  description = "ElastiCache cluster ID"
  value       = aws_elasticache_cluster.redis.id
}

output "ebs_volume_id" {
  description = "EBS volume ID"
  value       = aws_ebs_volume.data.id
}

output "sns_topic_arn" {
  description = "SNS topic ARN for audit logs"
  value       = aws_sns_topic.audit.arn
}
