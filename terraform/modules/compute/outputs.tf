output "alb_arn" {
  description = "ALB ARN"
  value       = aws_lb.main.arn
}

output "alb_dns_name" {
  description = "ALB DNS name"
  value       = aws_lb.main.dns_name
}

output "alb_zone_id" {
  description = "ALB zone ID"
  value       = aws_lb.main.zone_id
}

output "target_group_arn" {
  description = "Target group ARN"
  value       = aws_lb_target_group.app.arn
}

output "ecr_repository_urls" {
  description = "ECR repository URLs"
  value       = { for k, v in aws_ecr_repository.app : k => v.repository_url }
}

output "ecr_repository_arns" {
  description = "ECR repository ARNs"
  value       = { for k, v in aws_ecr_repository.app : k => v.arn }
}

output "lambda_function_names" {
  description = "Lambda function names"
  value = concat(
    [for f in aws_lambda_function.data_processor : f.function_name],
    [for f in aws_lambda_function.notification_sender : f.function_name],
    [for f in aws_lambda_function.audit_logger : f.function_name],
    [for f in aws_lambda_function.report_generator : f.function_name]
  )
}

output "lambda_function_arns" {
  description = "Lambda function ARNs"
  value = concat(
    [for f in aws_lambda_function.data_processor : f.arn],
    [for f in aws_lambda_function.notification_sender : f.arn],
    [for f in aws_lambda_function.audit_logger : f.arn],
    [for f in aws_lambda_function.report_generator : f.arn]
  )
}

output "alb_logs_bucket_id" {
  description = "ALB logs S3 bucket ID"
  value       = aws_s3_bucket.alb_logs.id
}
