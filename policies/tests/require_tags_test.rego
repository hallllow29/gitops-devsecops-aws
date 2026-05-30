package main

test_deny_missing_tags {
  deny[_] with input as {
    "resource_changes": [
      {
        "address": "aws_vpc.test",
        "type": "aws_vpc",
        "change": {
          "after": {
            "tags": {}
          }
        }
      }
    ]
  }
}

test_allow_required_tags {
  not deny[_] with input as {
    "resource_changes": [
      {
        "address": "aws_vpc.test",
        "type": "aws_vpc",
        "change": {
          "after": {
            "tags": {
              "Environment": "prod",
              "Name": "prod-vpc"
            }
          }
        }
      }
    ]
  }
}