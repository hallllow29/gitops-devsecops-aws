# Getting Started

## Prerequisites

Install the following tools before starting:

```bash
# Terraform
brew install terraform  # or download from terraform.io

# Terragrunt
brew install terragrunt  # or download from terragrunt.gruntwork.io

# AWS CLI
brew install awscli

# kubectl
brew install kubectl

# Helm
brew install helm

# Conftest (OPA)
brew install conftest
```

## Step 1 — Fork and clone

```bash
git clone https://github.com/YOUR_ORG/gitops-devsecops-aws
cd gitops-devsecops-aws
```

## Step 2 — Configure AWS

```bash
aws configure
# AWS Access Key ID: YOUR_KEY
# AWS Secret Access Key: YOUR_SECRET
# Default region: eu-central-1
```

## Step 3 — Bootstrap

Run once to create S3 backends and DynamoDB lock tables:

```bash
make bootstrap
```

## Step 4 — Configure GitHub

### Create environments

Go to `Settings → Environments` and create:

- `dev-approval` — add yourself as required reviewer
- `production` — add yourself as required reviewer

### Add secrets

Go to `Settings → Secrets → Actions` and add:

| Secret              | Where to get it                        |
|---------------------|----------------------------------------|
| `AWS_ROLE_ARN`      | Output of bootstrap terraform          |
| `DEFECTDOJO_TOKEN`  | DefectDojo UI → API v2 → Token         |
| `DEFECTDOJO_URL`    | Your DefectDojo URL in Paris           |
| `SONAR_TOKEN`       | SonarQube UI → My Account → Security   |
| `SONAR_HOST_URL`    | Your SonarQube URL in Paris            |
| `SLACK_WEBHOOK`     | Slack → Apps → Incoming Webhooks       |

## Step 5 — Deploy security tools

```bash
make up-security
```

This deploys to Paris (~15-20 minutes):

- EKS cluster
- SonarQube, Harbor, DefectDojo, Vault, Prometheus

## Step 6 — Update kubeconfig

```bash
make kubeconfig-security
```

## Step 7 — Deploy production

```bash
make up-prod
```

## Step 8 — Start using GitOps

1. Create a feature branch from `dev`
2. Make your changes
3. Push to `dev` — security scan runs automatically
4. Open PR to `main` — PR checks run automatically
5. Get approval and merge
6. Approve dev deployment in GitHub
7. Test in Ireland
8. Approve production deployment
9. Changes go live in Frankfurt