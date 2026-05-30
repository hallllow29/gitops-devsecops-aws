variable "environment" {
    description = "Environment name (prod, dev, security)"
    type = string
}

variable "kubernetes_version" {
    description = "Kubernetes version to use for the EKS cluster"
    default = "1.31"
    type = string
}

variable "private_subnet_ids" {
    description = "Map of private subnet IDs from the networking module"
    type = map(string)
}

