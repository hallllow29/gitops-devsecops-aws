# environments/prod/networking/terragrunt.hcl
include "root" {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  source = "../../../modules/networking"
}

inputs = {
  environment = "prod"
  vpc_cidr    = "10.0.0.0/16"

  public_subnets = {
    "eu-central-1a" = "10.0.1.0/24"
    "eu-central-1b" = "10.0.2.0/24"
  }

  private_subnets = {
    "eu-central-1a" = "10.0.3.0/24"
    "eu-central-1b" = "10.0.4.0/24"
  }
}