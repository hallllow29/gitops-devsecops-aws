package main

test_deny_no_launch_template {
  deny[_] with input as {
    "resource_changes": [
      {
        "address": "aws_eks_node_group.test",
        "type": "aws_eks_node_group",
        "change": {
          "after": {
            "launch_template": [
              {
                "name": ""
              }
            ]
          }
        }
      }
    ]
  }
}

test_allow_launch_template {
  not deny[_] with input as {
    "resource_changes": [
      {
        "address": "aws_eks_node_group.test",
        "type": "aws_eks_node_group",
        "change": {
          "after": {
            "launch_template": [
              {
                "name": "my-launch-template"
              }
            ]
          }
        }
      }
    ]
  }
}