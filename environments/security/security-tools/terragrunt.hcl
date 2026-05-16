include "root" {
  path = find_in_parent_folders()
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