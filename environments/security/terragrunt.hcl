locals {
  environment_tags = {
    Project     = "gitops-devsecops-aws"
    Environment = "prod"
    ManagedBy   = "terraform"
  }
}