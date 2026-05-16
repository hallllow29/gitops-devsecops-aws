package main

deny[msg] {
  resource := input.resource_changes[_]
  resource.type == "aws_eks_cluster"
  count(resource.change.after.encryption_config) == 0
  msg := sprintf("EKS cluster '%v' does not have secrets encryption enabled", [resource.address])
}