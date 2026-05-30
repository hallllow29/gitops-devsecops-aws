package main

deny[msg] {
  resource := input.resource_changes[_]
  not resource.change.after.tags.Environment
  msg := sprintf("Resource '%v' is missing required 'Environment' tag", [resource.address])
}

deny[msg] {
  resource := input.resource_changes[_]
  not resource.change.after.tags.Name
  msg := sprintf("Resource '%v' is missing required 'Name' tag", [resource.address])
}