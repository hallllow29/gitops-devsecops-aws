# Runbook — Deploy Security Tools

Deploys all security tools to Paris (eu-west-3).

## Prerequisites

- Bootstrap completed
- AWS credentials configured
- kubectl installed

## Steps

### 1. Deploy infrastructure

```bash
make up-security
```

Takes ~15-20 minutes.

### 2. Update kubeconfig

```bash
make kubeconfig-security
```

### 3. Verify cluster

```bash
kubectl get nodes
kubectl get pods -n security-tools
```

### 4. Install Helm charts

```bash
# Add repositories
helm repo add sonarqube https://SonarSource.github.io/helm-chart-sonarqube
helm repo add harbor https://helm.goharbor.io
helm repo add defectdojo https://raw.githubusercontent.com/DefectDojo/django-DefectDojo/helm-charts
helm repo add hashicorp https://helm.releases.hashicorp.com
helm repo add prometheus https://prometheus-community.github.io/helm-charts
helm repo update

# Install
helm install sonarqube sonarqube/sonarqube \
  -n security-tools \
  -f kubernetes/helm/sonarqube/values.yaml

helm install harbor harbor/harbor \
  -n security-tools \
  -f kubernetes/helm/harbor/values.yaml

helm install defectdojo defectdojo/defectdojo \
  -n security-tools \
  -f kubernetes/helm/defectdojo/values.yaml

helm install vault hashicorp/vault \
  -n security-tools \
  -f kubernetes/helm/vault/values.yaml

helm install prometheus prometheus/kube-prometheus-stack \
  -n security-tools \
  -f kubernetes/helm/kube-prometheus-stack/values.yaml
```

### 5. Verify all pods are running

```bash
kubectl get pods -n security-tools
```

## Troubleshooting

**Pods stuck in Pending**
Check if EBS CSI Driver is installed:

```bash
kubectl get pods -n kube-system | grep ebs
```

**ImagePullBackOff**
Verify Harbor is accessible and imagePullSecrets are configured.