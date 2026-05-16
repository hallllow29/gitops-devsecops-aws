# GitOps DevSecOps AWS

A production-ready, security-first GitOps template for small teams and companies.
Deploy a fully automated infrastructure across 3 AWS regions with built-in security
scanning, policy enforcement, and secret management.

## Architecture

```text
Frankfurt (eu-central-1) → Production workloads
Ireland (eu-west-1)      → Ephemeral dev environment (destroyed after testing)
Paris (eu-west-3)        → Security tools hub
```

### Security Tools (Paris)

- **SonarQube** — SAST and code quality
- **Harbor** — Private container registry
- **DefectDojo** — Vulnerability management
- **Dependency Track** — Software composition analysis
- **Vault** — Secrets management
- **Prometheus + Grafana** — Monitoring and observability
- **Atlantis** — Terraform pull request automation

## GitOps Flow

```text
push to dev
    │
    ▼
Security Scan (TruffleHog, KICS, Checkov)
    │
    ▼
Open PR to main
    │
    ▼
PR Checks (fmt, validate, plan, OPA, SonarQube, Trivy)
    │
    ▼
Manual approval
    │
    ▼
Deploy to Ireland (dev)
    │
    ▼
Smoke tests + Manual testing
    │
    ▼
Manual approval
    │
    ▼
Destroy Ireland → Deploy to Frankfurt (prod)
```

## Prerequisites

- [Terraform](https://www.terraform.io/downloads) >= 1.0.0
- [Terragrunt](https://terragrunt.gruntwork.io/docs/getting-started/install/) >= 0.55.0
- [AWS CLI](https://aws.amazon.com/cli/) configured
- [kubectl](https://kubernetes.io/docs/tasks/tools/)
- [Helm](https://helm.sh/docs/intro/install/)
- [Conftest](https://www.conftest.dev/)
- GitHub account with Actions enabled

## Quick Start

### 1. Clone the repository

```bash
git clone https://github.com/YOUR_ORG/gitops-devsecops-aws
cd gitops-devsecops-aws
```

### 2. Configure AWS credentials

```bash
aws configure
```

### 3. Run bootstrap (once only)

Creates S3 backends and DynamoDB lock tables across all 3 regions.

```bash
make bootstrap
```

### 4. Deploy security tools (Paris)

```bash
make up-security
```

### 5. Deploy production (Frankfurt)

```bash
make up-prod
```

## GitHub Setup

### Secrets required

| Secret | Description |
|--------|-------------|
| `AWS_ROLE_ARN` | IAM role ARN for GitHub Actions OIDC |
| `DEFECTDOJO_TOKEN` | DefectDojo API token |
| `DEFECTDOJO_URL` | DefectDojo URL (Paris) |
| `SONAR_TOKEN` | SonarQube authentication token |
| `SONAR_HOST_URL` | SonarQube URL (Paris) |
| `SLACK_WEBHOOK` | Slack webhook for notifications |

### Environments required

| Environment | Purpose |
|-------------|---------|
| `dev-approval` | Manual approval gate before promoting to prod |
| `production` | Manual approval gate before deploying to Frankfurt |

Go to `Settings → Environments → New environment` to create them.

### Branch protection

Enable branch protection on `main`:

- Require pull request reviews
- Require status checks to pass (security-scan, pr-checks)
- Restrict pushes to main

## Cost Estimate

| Resource                            | Cost          |
|--------------------------------------|---------------|
| EKS control plane × 3                | ~$216/month   |
| EC2 nodes (spot, t3.medium) × 3     | ~$30/month    |
| S3 + DynamoDB                        | ~$5/month     |
| **Total**                            | **~$250/month** |

> **Tip:** Stop EC2 nodes when not in use to reduce costs significantly.
> For learning purposes, spin up one region at a time.

## Makefile Commands

```bash
make help           # List all available commands
make bootstrap      # Create S3 backends and DynamoDB tables (run once)
make up-all         # Deploy all environments
make down-all       # Destroy all environments
make up-prod        # Deploy Frankfurt (prod)
make up-dev         # Deploy Ireland (dev)
make up-security    # Deploy Paris (security tools)
make fmt            # Format all Terraform files
make validate       # Validate all Terraform files
make scan           # Run security scans locally
make test-policies  # Run OPA policy tests
```

## Security Gates

Every change goes through multiple security gates:

| Gate                | Tool          | When                      |
|---------------------|---------------|---------------------------|
| Secrets scan        | TruffleHog    | Every push to dev         |
| IaC scan            | KICS          | Every push to dev         |
| IaC scan            | Checkov       | Every push to dev         |
| Code quality        | SonarQube     | Every PR                  |
| Policy enforcement  | OPA/Conftest  | Every PR                  |
| Container scan      | Trivy         | Every PR                  |
| Vulnerability mgmt  | DefectDojo    | Aggregates all results    |

## OPA Policies

Policies are enforced on every PR via Conftest:

| Policy                      | Description                                        |
|-----------------------------|---------------------------------------------------|
| `no_public_s3`              | S3 buckets must have public access blocked        |
| `enforce_imdsv2`            | EC2 instances must use IMDSv2                     |
| `require_encryption`        | EBS volumes must be encrypted                     |
| `eks_private_endpoint`      | EKS clusters must have private endpoint           |
| `no_privileged_containers`  | EKS node groups must have launch template         |
| `require_tags`              | All resources must have Name and Environment tags |
| `no_wide_ingress`           | SSH must not be open to 0.0.0.0/0                 |
| `eks_secrets_encryption`    | EKS clusters must encrypt secrets                 |

## Module Structure

```text
modules/
├── networking/      # VPC, subnets, IGW, fck-nat, route tables
├── eks/             # EKS cluster, node groups, IAM roles
├── eks-addons/      # EBS CSI, CoreDNS, kube-proxy, LBC
├── security-tools/  # IAM roles for security tools, Harbor S3
└── prod-services/   # Generic IAM role for production workloads
```

## Customisation

### Adding your own production service

1. Update `modules/prod-services/main.tf` with your application resources
2. Add required IAM permissions to `aws_iam_role.app`
3. Create Kubernetes manifests in `kubernetes/manifests/prod-services/`
4. Push to `dev` branch and follow the GitOps flow

### Scaling security tools

Default instance sizes are optimised for small teams. To scale:

```hcl
# environments/security/eks/terragrunt.hcl
inputs = {
  instance_types = ["t3.large"]  # upgrade from t3.medium
}
```

## Contributing

1. Fork the repository
2. Create a feature branch from `dev`
3. Make your changes
4. Push to your fork and open a PR to `dev`
5. Security scans run automatically
6. Once approved, changes flow through the full GitOps pipeline

## License

MIT — free to use, modify, and distribute.
