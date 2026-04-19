output "vpc_id" {
  description = "VPC ID"
  value       = module.networking.vpc_id
}

output "private_subnet_ids" {
  description = "Private subnet IDs"
  value       = module.networking.private_subnet_ids
}

output "public_subnet_ids" {
  description = "Public subnet IDs"
  value       = module.networking.public_subnet_ids
}

output "cluster_id" {
  description = "EKS cluster ID"
  value       = module.eks.cluster_id
}

output "cluster_endpoint" {
  description = "EKS cluster API endpoint"
  value       = module.eks.cluster_endpoint
}

output "cluster_oidc_provider_arn" {
  description = "OIDC provider ARN for EKS"
  value       = module.eks.oidc_provider_arn
}

output "rds_endpoint" {
  description = "RDS database endpoint"
  value       = module.data_stores.rds_endpoint
  sensitive   = true
}

output "rds_instance_id" {
  description = "RDS instance ID"
  value       = module.data_stores.rds_instance_id
}

output "s3_bucket_ids" {
  description = "S3 bucket IDs"
  value       = module.data_stores.s3_bucket_ids
}

output "elasticache_endpoint" {
  description = "ElastiCache Redis endpoint"
  value       = module.data_stores.elasticache_endpoint
  sensitive   = true
}

output "alb_dns_name" {
  description = "ALB DNS name"
  value       = module.compute.alb_dns_name
}

output "alb_arn" {
  description = "ALB ARN"
  value       = module.compute.alb_arn
}

output "lambda_function_names" {
  description = "Lambda function names"
  value       = module.compute.lambda_function_names
}

output "ecr_repository_urls" {
  description = "ECR repository URLs"
  value       = module.compute.ecr_repository_urls
}

output "kms_key_id" {
  description = "KMS key ID for encryption"
  value       = module.security.kms_key_id
}

output "cloudtrail_arn" {
  description = "CloudTrail ARN"
  value       = module.security.cloudtrail_arn
}
