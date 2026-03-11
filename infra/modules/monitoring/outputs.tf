output "sns_topic_arn" {
  description = "SNS topic ARN for alerts"
  value       = aws_sns_topic.alerts.arn
}

output "lambda_function_name" {
  description = "Lambda health monitor function name"
  value       = aws_lambda_function.health_monitor.function_name
}