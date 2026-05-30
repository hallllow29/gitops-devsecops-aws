# environments/dev/networking/terragrunt.hcl
include "root" {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  source = "../../../modules/networking"
}

inputs = {
  environment = "dev"
  vpc_cidr    = "10.1.0.0/16"

  public_subnets = {
    "eu-west-1a" = "10.1.1.0/24"
    "eu-west-1b" = "10.1.2.0/24"
  }

  private_subnets = {
    "eu-west-1a" = "10.1.3.0/24"
    "eu-west-1b" = "10.1.4.0/24"
  }
}