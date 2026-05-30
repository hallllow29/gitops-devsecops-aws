package main

deny[msg] {
  resource := input.resource_changes[_]
  resource.type == "aws_instance"
  resource.change.after.metadata_options[_].http_tokens != "required"
  msg := sprintf("EC2 instance '%v' does not have IMDSv2 enforced", [resource.address])
}