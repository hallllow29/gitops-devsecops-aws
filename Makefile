.PHONY: bootstrap up-all down-all up-prod up-dev up-security down-prod down-dev down-security fmt validate scan help

# Bootstrap — run once before everything else
bootstrap:
	cd bootstrap && terraform init && terraform apply

# Bring up all environments
up-all:
	terragrunt run-all apply --terragrunt-working-dir environments

# Tear down all environments
down-all:
	terragrunt run-all destroy --terragrunt-working-dir environments

# Prod
up-prod:
	terragrunt run-all apply --terragrunt-working-dir environments/prod

down-prod:
	terragrunt run-all destroy --terragrunt-working-dir environments/prod

# Dev
up-dev:
	terragrunt run-all apply --terragrunt-working-dir environments/dev

down-dev:
	terragrunt run-all destroy --terragrunt-working-dir environments/dev

# Security
up-security:
	terragrunt run-all apply --terragrunt-working-dir environments/security

down-security:
	terragrunt run-all destroy --terragrunt-working-dir environments/security

# Terraform
fmt:
	terragrunt run-all fmt --terragrunt-working-dir environments

validate:
	terragrunt run-all validate --terragrunt-working-dir environments

# Security scan local
scan:
	kics scan -p . -o results/
	trufflehog git file://. --only-verified
	checkov -d . --framework terraform

# OPA tests
test-policies:
	conftest verify --policy policies/

# Update kubeconfig
kubeconfig-prod:
	aws eks update-kubeconfig --name prod-eks --region eu-central-1

kubeconfig-dev:
	aws eks update-kubeconfig --name dev-eks --region eu-west-1

kubeconfig-security:
	aws eks update-kubeconfig --name security-eks --region eu-west-3

# Help
help:
	@echo "Available commands:"
	@echo "  make bootstrap        - Run once to create S3 backends and DynamoDB tables"
	@echo "  make up-all           - Deploy all environments"
	@echo "  make down-all         - Destroy all environments"
	@echo "  make up-prod          - Deploy prod (Frankfurt)"
	@echo "  make down-prod        - Destroy prod"
	@echo "  make up-dev           - Deploy dev (Ireland)"
	@echo "  make down-dev         - Destroy dev"
	@echo "  make up-security      - Deploy security tools (Paris)"
	@echo "  make down-security    - Destroy security tools"
	@echo "  make fmt              - Format all Terraform files"
	@echo "  make validate         - Validate all Terraform files"
	@echo "  make scan             - Run security scans locally"
	@echo "  make test-policies    - Run OPA policy tests"
	@echo "  make kubeconfig-prod  - Update kubeconfig for prod cluster"
	@echo "  make kubeconfig-dev   - Update kubeconfig for dev cluster"
	@echo "  make kubeconfig-security - Update kubeconfig for security cluster"