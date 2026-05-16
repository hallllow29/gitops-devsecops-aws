locals {
  environment = basename(dirname(get_terragrunt_dir()))
  region = {
    prod     = "eu-central-1"
    dev      = "eu-west-1"
    security = "eu-west-3"
  }[local.environment]
}

remote_state {
  backend = "s3"
  config = {
    bucket         = "gitops-state-${local.environment}"
    key            = "${path_relative_to_include()}/terraform.tfstate"
    region         = local.region
    dynamodb_table = "gitops-lock-${local.environment}"
    encrypt        = true
  }
}

generate "provider" {
  path      = "provider.tf"
  if_exists = "overwrite"
  contents  = <<EOF
provider "aws" {
  region = "${local.region}"
}
EOF
}