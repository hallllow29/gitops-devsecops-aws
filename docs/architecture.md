# Architecture

## Overview

This project deploys a security-first GitOps infrastructure across 3 AWS regions,
each with a specific purpose and responsibility.

## Regions

### Frankfurt (eu-central-1) — Production

- Runs production workloads
- EKS cluster with spot instances
- Only receives deployments after passing all security gates
- Never deployed to directly — always through the GitOps pipeline

### Ireland (eu-west-1) — Dev

- Ephemeral environment — exists only during testing
- Provisioned automatically after PR approval
- Destroyed after manual testing and approval
- Mirrors production infrastructure exactly

### Paris (eu-west-3) — Security Tools

- Always-on security hub
- Hosts all security and observability tooling
- Self-hosted GitHub Actions runners
- Central point for vulnerability aggregation

## Network Architecture

```text
Paris (Security Hub)
├── VPC 10.2.0.0/16
│   ├── Public subnets  → 10.2.1.0/24, 10.2.2.0/24
│   └── Private subnets → 10.2.3.0/24, 10.2.4.0/24
│
Frankfurt (Prod)
├── VPC 10.0.0.0/16
│   ├── Public subnets  → 10.0.1.0/24, 10.0.2.0/24
│   └── Private subnets → 10.0.3.0/24, 10.0.4.0/24
│
Ireland (Dev)
├── VPC 10.1.0.0/16
│   ├── Public subnets  → 10.1.1.0/24, 10.1.2.0/24
│   └── Private subnets → 10.1.3.0/24, 10.1.4.0/24
```

## Kubernetes Architecture

Each region runs an EKS cluster with:

- Spot instances (t3.medium) for cost efficiency
- Private endpoint only — no public API server
- IRSA for pod-level AWS permissions
- EBS CSI Driver for persistent storage
- AWS Load Balancer Controller for ingress

## Security Architecture

```text
Developer commit
      │
      ▼
TruffleHog → no secrets in code
KICS       → no IaC misconfigurations
Checkov    → no IaC policy violations
      │
      ▼
PR opened
      │
      ▼
OPA/Conftest → policies enforced on terraform plan
SonarQube    → code quality gate
Trivy        → no critical vulnerabilities
      │
      ▼
Deploy to dev → manual testing
      │
      ▼
Deploy to prod
```

## Secret Management

All secrets are managed by Vault (Paris):

- Pods authenticate via Kubernetes ServiceAccount + IRSA
- Secrets injected at runtime via Vault Agent Injector
- No secrets stored in Kubernetes Secrets or environment variables
- GitHub Actions uses OIDC — no static AWS credentials