output "cluster_name" {
  value = aws_eks_cluster.main.name
}

output "cluster_endpoints" {
   value = aws_eks_cluster.main.endpoint
}

output "cluster_certificate_authority" {
  value = aws_eks_cluster.main.certificate_authority[0].data
}

output "oidc_issuer_url" {
  value = aws_eks_cluster.main.identity[0].oidc[0].issuer
}
