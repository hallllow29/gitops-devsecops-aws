include "root" {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  source = "../../../modules/security-tools"
}

dependency "eks" {
  config_path = "../eks"
}

inputs = {
  environment        = "security"
  oidc_issuer_url = dependency.eks.outputs.oidc_issuer_url
}