# Runbook — Bootstrap

Run this once before anything else.

## What it creates

- 3 S3 buckets for Terraform state (prod, dev, security)
- 3 DynamoDB tables for state locking (prod, dev, security)
- IAM OIDC provider for GitHub Actions
- IAM role for GitHub Actions

## Steps

### 1. Configure AWS credentials

```bash
aws configure
```

### 2. Run bootstrap

```bash
make bootstrap
```

Or manually:

```bash
cd bootstrap
terraform init
terraform apply
```

### 3. Note the outputs

After apply, note:

- `github_actions_role_arn` → add to GitHub Secrets as `AWS_ROLE_ARN`
- `bucket_names` → verify 3 buckets were created

## Troubleshooting

**Bucket already exists**
S3 bucket names are globally unique. Change the bucket name prefix in `bootstrap/variables.tf`.

**DynamoDB table already exists**
Change the table name prefix in `bootstrap/variables.tf`.

**Insufficient permissions**
Your AWS user needs AdministratorAccess or equivalent to run bootstrap.