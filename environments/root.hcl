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
    region         = "eu-central-1"
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

generate "backend" {
  path      = "backend.tf"
  if_exists = "overwrite"
  contents  = <<EOF
terraform {
  backend "s3" {}
}
EOF
}