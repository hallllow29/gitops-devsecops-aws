package main

deny[msg] {
  resource := input.resource_changes[_]
  resource.type == "aws_eks_cluster"
  resource.change.after.vpc_config[_].endpoint_public_access == true
  msg := sprintf("EKS cluster '%v' has public endpoint enabled", [resource.address])
}