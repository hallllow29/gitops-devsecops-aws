package main

test_deny_no_imdsv2 {
  deny[_] with input as {
    "resource_changes": [
      {
        "address": "aws_instance.test",
        "type": "aws_instance",
        "change": {
          "after": {
            "metadata_options": [
              {
                "http_tokens": "optional"
              }
            ]
          }
        }
      }
    ]
  }
}

test_allow_imdsv2 {
  not deny[_] with input as {
    "resource_changes": [
      {
        "address": "aws_instance.test",
        "type": "aws_instance",
        "change": {
          "after": {
            "metadata_options": [
              {
                "http_tokens": "required"
              }
            ]
          }
        }
      }
    ]
  }
}