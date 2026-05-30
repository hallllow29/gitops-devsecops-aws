variable "regions" {
  description = "AWS regions per environment"
  type        = map(string)
  default = {
    prod     = "eu-central-1"
    dev      = "eu-west-1"
    security = "eu-west-3"
  }
}

variable "github_repo" {
  description = "GitHub repository in the format owner/repo. Used to scope the GitHub Actions OIDC trust policy."
  type        = string
}
