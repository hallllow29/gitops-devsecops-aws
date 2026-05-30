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

variable "enable_flow_logs" {
  description = "Enable VPC flow logs to CloudWatch"
  type        = bool
  default     = true
}

variable "flow_log_retention_days" {
  description = "Retention in days for VPC flow logs CloudWatch log group"
  type        = number
  default     = 7
}

