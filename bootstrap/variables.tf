variable "regions" {
  description = "AWS regions per environment"
  type        = map(string)
  default = {
    prod     = "eu-central-1"
    dev      = "eu-west-1"
    security = "eu-west-3"
  }
}