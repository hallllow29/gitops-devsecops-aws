# environments/security/networking/terragrunt.hcl
include "root" {
  path = find_in_parent_folders()
}

terraform {
  source = "../../../modules/networking"
}

inputs = {
  environment = "security"
  vpc_cidr    = "10.2.0.0/16"

  public_subnets = {
    "eu-west-3a" = "10.2.1.0/24"
    "eu-west-3b" = "10.2.2.0/24"
  }

  private_subnets = {
    "eu-west-3a" = "10.2.3.0/24"
    "eu-west-3b" = "10.2.4.0/24"
  }
}