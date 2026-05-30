package main

deny[msg] {
  resource := input.resource_changes[_]
  resource.type == "aws_ebs_volume"
  resource.change.after.encrypted != true
  msg := sprintf("EBS volume '%v' is not encrypted", [resource.address])
}