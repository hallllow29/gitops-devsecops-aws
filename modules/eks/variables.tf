variable "environment" {
  description = "Environment name (prod, dev, security)"
  type        = string
}

variable "kubernetes_version" {
  description = "Kubernetes version to use for the EKS cluster"
  default     = "1.31"
  type        = string
}

variable "private_subnet_ids" {
  description = "Map of private subnet IDs from the networking module"
  type        = map(string)
}

variable "instance_types" {
  description = "EC2 instance types for the node group"
  type        = list(string)
  default     = ["t3.large"]
}

variable "capacity_type" {
  description = "ON_DEMAND or SPOT"
  type        = string
  default     = "SPOT"
}

variable "desired_size" {
  description = "Desired number of nodes"
  type        = number
  default     = 2
}

variable "max_size" {
  description = "Max number of nodes"
  type        = number
  default     = 4
}

variable "min_size" {
  description = "Min number of nodes"
  type        = number
  default     = 2
}
