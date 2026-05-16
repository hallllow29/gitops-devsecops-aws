package main

test_deny_public_eks {
  deny[_] with input as {
    "resource_changes": [
      {
        "address": "aws_eks_cluster.test",
        "type": "aws_eks_cluster",
        "change": {
          "after": {
            "vpc_config": [
              {
                "endpoint_public_access": true
              }
            ]
          }
        }
      }
    ]
  }
}

test_allow_private_eks {
  not deny[_] with input as {
    "resource_changes": [
      {
        "address": "aws_eks_cluster.test",
        "type": "aws_eks_cluster",
        "change": {
          "after": {
            "vpc_config": [
              {
                "endpoint_public_access": false
              }
            ]
          }
        }
      }
    ]
  }
}