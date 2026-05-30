#!/bin/bash
set -e

echo "Running smoke tests..."

echo "Checking EKS cluster..."
kubectl get nodes || exit 1

echo "Checking pods..."
FAILED_PODS=$(kubectl get pods -A | grep -v Running | grep -v Completed | grep -v NAME)
if [ -n "$FAILED_PODS" ]; then
  echo "Failed pods found:"
  echo "$FAILED_PODS"
  exit 1
fi

echo "Checking Vault..."
vault status || exit 1

echo "All smoke tests passed!"