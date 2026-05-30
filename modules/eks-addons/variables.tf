variable "cluster_name" {
  description = "Name of the EKS cluster where addons will be installed"
  type        = string
}

variable "oidc_issuer_url" {
  description = "OIDC issuer URL of the EKS cluster, used for IRSA configuration"
  type        = string
}

variable "addon_versions" {
  description = "Map of addon names to their versions, override per environment if needed"
  type        = map(string)
  default = {
    ebs_csi_driver = "v1.28.0-eksbuild.1"
    coredns        = "v1.11.1-eksbuild.4"
    kube_proxy     = "v1.31.0-eksbuild.5"
  }
}

variable "environment" {
    description = "Environment name (prod, dev, security)"
    type = string
}
