output "lbc_role_arn" {
  description = "ARN of the IAM role for the AWS Load Balancer Controller"
  value       = aws_iam_role.lbc.arn
}