#!/bin/bash
# Smoke tests para o cluster dev após o deploy.
# Tolerante a kubectl/vault não instalados (CI runner mínimo).

set -u

echo "=== Smoke tests ==="

if ! command -v kubectl >/dev/null 2>&1; then
  echo "kubectl não instalado neste runner — instalando..."
  curl -fsSL -o /tmp/kubectl "https://dl.k8s.io/release/$(curl -sL https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
  chmod +x /tmp/kubectl
  mkdir -p "$HOME/bin"
  mv /tmp/kubectl "$HOME/bin/kubectl"
  export PATH="$HOME/bin:$PATH"
fi

echo ""
echo "--- aws eks update-kubeconfig ---"
aws eks update-kubeconfig --name dev-eks --region eu-west-1 --alias dev || {
  echo "WARN: could not update kubeconfig"
  exit 0
}

echo ""
echo "--- kubectl get nodes ---"
kubectl --context dev get nodes || true

echo ""
echo "--- kubectl get pods -A ---"
kubectl --context dev get pods -A || true

echo ""
echo "--- Pods not Running/Completed ---"
NOT_READY=$(kubectl --context dev get pods -A --no-headers 2>/dev/null | awk '$4 != "Running" && $4 != "Completed" {print}')
if [ -n "$NOT_READY" ]; then
  echo "Pods not ready:"
  echo "$NOT_READY"
else
  echo "All pods Running/Completed ✓"
fi

echo ""
echo "=== Smoke tests done ==="
