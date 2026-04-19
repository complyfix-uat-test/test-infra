output "alarm_topic_arn" {
  description = "SNS topic ARN for alarms"
  value       = aws_sns_topic.alarms.arn
}

output "secure_alarm_topic_arn" {
  description = "Encrypted SNS topic ARN for alarms"
  value       = length(aws_sns_topic.secure_alarms) > 0 ? aws_sns_topic.secure_alarms[0].arn : ""
}

output "dashboard_url" {
  description = "CloudWatch dashboard URL"
  value       = "https://console.aws.amazon.com/cloudwatch/home#dashboards:name=${aws_cloudwatch_dashboard.main.dashboard_name}"
}

output "log_group_names" {
  description = "CloudWatch log group names"
  value = {
    eks_cluster = aws_cloudwatch_log_group.eks_cluster.name
    eks_api     = aws_cloudwatch_log_group.eks_api.name
    eks_audit   = aws_cloudwatch_log_group.eks_audit.name
    rds_logs    = aws_cloudwatch_log_group.rds_logs.name
  }
}
