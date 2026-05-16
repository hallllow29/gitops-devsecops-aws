include "root" {
  path = find_in_parent_folders()
}

terraform {
  source = "../../../modules/eks"
}

dependency "networking" {
  config_path = "../networking"
}

inputs = {
  environment        = "prod"
  kubernetes_version = "1.31"
  private_subnet_ids = dependency.networking.outputs.private_subnet_ids
}