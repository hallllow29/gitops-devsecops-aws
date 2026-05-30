package main

deny[msg] {
  resource := input.resource_changes[_]
  resource.type == "aws_eks_node_group"
  resource.change.after.launch_template[_].name == ""
  msg := sprintf("EKS node group '%v' does not have a launch template defined", [resource.address])
}