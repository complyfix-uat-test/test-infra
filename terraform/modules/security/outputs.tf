output "kms_key_id" {
  description = "KMS key ID"
  value       = aws_kms_key.main.key_id
}

output "kms_key_arn" {
  description = "KMS key ARN"
  value       = aws_kms_key.main.arn
}

output "kms_alias_name" {
  description = "KMS key alias"
  value       = aws_kms_alias.main.name
}

output "eks_sa_role_arn" {
  description = "EKS service account role ARN"
  value       = aws_iam_role.eks_sa_role.arn
}

output "lambda_execution_role_arn" {
  description = "Lambda execution role ARN"
  value       = aws_iam_role.lambda_execution.arn
}

output "cloudtrail_arn" {
  description = "CloudTrail ARN"
  value       = length(aws_cloudtrail.main) > 0 ? aws_cloudtrail.main[0].arn : ""
}

output "cloudtrail_s3_bucket_name" {
  description = "S3 bucket for CloudTrail logs"
  value       = var.s3_bucket_name
}
