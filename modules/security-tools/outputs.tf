output "sonarqube_role_arn" {
  description = "ARN of the IAM role for SonarQube"
  value       = aws_iam_role.sonarqube.arn
}

output "harbor_role_arn" {
  description = "ARN of the IAM role for Harbor"
  value       = aws_iam_role.harbor.arn
}

output "vault_role_arn" {
  description = "ARN of the IAM role for Vault"
  value       = aws_iam_role.vault.arn
}

output "dtrack_role_arn" {
  description = "ARN of the IAM role for Dependency Track"
  value       = aws_iam_role.dtrack.arn
}

output "prometheus_role_arn" {
  description = "ARN of the IAM role for Prometheus"
  value       = aws_iam_role.prometheus.arn
}