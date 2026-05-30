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

variable "enable_secrets_encryption" {
  description = "Enable EKS secrets encryption at rest via KMS (cluster-only, requires recreate)"
  type        = bool
  default     = false
}

variable "enable_control_plane_logs" {
  description = "Enable EKS control plane logging to CloudWatch"
  type        = bool
  default     = true
}

variable "endpoint_public_access_cidrs" {
  description = "CIDRs allowed to reach the EKS public endpoint. Restrict in production."
  type        = list(string)
  default     = ["0.0.0.0/0"]
}
