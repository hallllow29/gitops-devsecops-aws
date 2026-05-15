output "bucket_names" {
  value  = {
    for k, v in aws_s3_bucket.state : k => v.bucket
  }
}

output "dyname_names" {
    value = {
        for k, v in aws_dynamodb_table.state : k => v.name
    }
}