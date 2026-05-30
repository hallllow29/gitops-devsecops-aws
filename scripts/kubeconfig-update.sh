#!/bin/bash
set -e

echo "Updating kubeconfig for all clusters..."

aws eks update-kubeconfig \
  --name prod-eks \
  --region eu-central-1

aws eks update-kubeconfig \
  --name dev-eks \
  --region eu-west-1

aws eks update-kubeconfig \
  --name security-eks \
  --region eu-west-3

echo "Kubeconfig updated for all clusters!"