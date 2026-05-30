package main

test_deny_public_s3 {
  deny[_] with input as {
    "resource_changes": [
      {
        "address": "aws_s3_bucket_public_access_block.test",
        "type": "aws_s3_bucket_public_access_block",
        "change": {
          "after": {
            "block_public_acls": false
          }
        }
      }
    ]
  }
}

test_allow_private_s3 {
  not deny[_] with input as {
    "resource_changes": [
      {
        "address": "aws_s3_bucket_public_access_block.test",
        "type": "aws_s3_bucket_public_access_block",
        "change": {
          "after": {
            "block_public_acls": true
          }
        }
      }
    ]
  }
}