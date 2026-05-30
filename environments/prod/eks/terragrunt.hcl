include "root" {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  source = "../../../modules/eks"
}

dependency "networking" {
  config_path = "../networking"
  mock_outputs = {
    private_subnet_ids = { "mock-a" = "subnet-mock00000000000a", "mock-b" = "subnet-mock00000000000b" }
    public_subnet_ids  = { "mock-a" = "subnet-mock00000000000c", "mock-b" = "subnet-mock00000000000d" }
    vpc_id             = "vpc-mock0000000000000"
  }
  mock_outputs_allowed_terraform_commands = ["plan", "validate", "init", "destroy", "show"]
}

inputs = {
  environment        = "prod"
  kubernetes_version = "1.31"
  private_subnet_ids = dependency.networking.outputs.private_subnet_ids
}