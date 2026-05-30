include "root" {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  source = "../../../modules/eks-addons"
}

dependency "eks" {
  config_path = "../eks"
  mock_outputs = {
    cluster_name      = "mock-cluster"
    oidc_issuer_url   = "https://oidc.eks.eu-west-1.amazonaws.com/id/MOCKMOCKMOCKMOCKMOCKMOCKMOCKMOCK"
    oidc_provider_arn = "arn:aws:iam::000000000000:oidc-provider/oidc.eks.eu-west-1.amazonaws.com/id/MOCKMOCKMOCK"
  }
  mock_outputs_allowed_terraform_commands = ["plan", "validate", "init", "destroy", "show"]
}

inputs = {
  environment        = "dev"
  cluster_name       = dependency.eks.outputs.cluster_name
  oidc_issuer_url = dependency.eks.outputs.oidc_issuer_url
}