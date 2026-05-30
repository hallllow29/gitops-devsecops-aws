output "app_role_arn" {
  description = "ARN of the IAM role for the application"
  value       = aws_iam_role.app.arn
}