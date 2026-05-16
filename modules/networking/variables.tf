variable "vpc_cidr" {
    description = "CIDR block for the VPC"
    type = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "public_subnets" {
  description = "Map of availability zone to CIDR block for public subnets"
  type        = map(string)
}

variable "private_subnets" {
  description = "Map of availability zone to CIDR block for private subnets"
  type        = map(string)
}

