package main

deny[msg] {
  resource := input.resource_changes[_]
  resource.type == "aws_s3_bucket_versioning"
  resource.change.after.versioning_configuration[_].mfa_delete != "Enabled"
  msg := sprintf("S3 bucket '%v' does not have MFA delete enabled", [resource.address])
}