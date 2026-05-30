include "root" {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  source = "../../../modules/eks-addons"
}

dependency "eks" {
  config_path = "../eks"
}

inputs = {
  environment        = "prod"
  cluster_name       = dependency.eks.outputs.cluster_name
  oidc_issuer_url = dependency.eks.outputs.oidc_issuer_url
}