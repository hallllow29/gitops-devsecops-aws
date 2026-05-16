variable "environment" {
    description = "Environment name (prod, dev, security)"
    type = string
}

variable "oidc_issuer_url" {
  description = "OIDC issuer URL of the EKS cluster, used for IRSA configuration"
  type        = string
}