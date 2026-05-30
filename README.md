# GitOps DevSecOps AWS

[![IaC: Terraform](https://img.shields.io/badge/IaC-Terraform%201.9%2B-7B42BC?logo=terraform&logoColor=white)](https://www.terraform.io/)
[![Orchestration: Terragrunt](https://img.shields.io/badge/orchestration-Terragrunt%201.0%2B-2BAACB)](https://terragrunt.gruntwork.io/)
[![Cloud: AWS](https://img.shields.io/badge/cloud-AWS-232F3E?logo=amazonaws&logoColor=FF9900)](https://aws.amazon.com/)
[![Runtime: Kubernetes](https://img.shields.io/badge/runtime-Kubernetes%201.31-326CE5?logo=kubernetes&logoColor=white)](https://kubernetes.io/)
[![CI/CD: GitHub Actions](https://img.shields.io/badge/CI%2FCD-GitHub%20Actions-2088FF?logo=githubactions&logoColor=white)](https://github.com/features/actions)
[![Methodology: GitOps](https://img.shields.io/badge/methodology-GitOps-3F73E3)](https://opengitops.dev/)
[![DevSecOps](https://img.shields.io/badge/security-DevSecOps-EE2200)](https://www.devsecops.org/)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

A **production-style GitOps + DevSecOps reference architecture** for AWS that demonstrates
how a small/medium team can ship infrastructure-as-code changes safely through automated
security gates, ephemeral dev environments, and human-gated promotion to production.

> **What problem does this solve?**
> "Someone wants to add a new service to our AWS platform. How do we make sure their
> change doesn't break production, doesn't introduce vulnerabilities, follows our
> policies, and gets reviewed by the right people — all automatically, with a clear
> audit trail?"
>
> This repo is the answer.

---

## Table of Contents

- [What's inside](#whats-inside)
- [Architecture](#architecture)
- [The GitOps flow](#the-gitops-flow)
- [Tech stack](#tech-stack)
- [Repository layout](#repository-layout)
- [Quick start](#quick-start)
- [How a developer uses this](#how-a-developer-uses-this)
- [Security controls](#security-controls)
- [OPA policies enforced](#opa-policies-enforced)
- [Cost](#cost)
- [Customisation](#customisation)
- [Roadmap](#roadmap)
- [Troubleshooting](#troubleshooting)
- [License](#license)

---

## What's inside

A **multi-region, multi-cluster** AWS Kubernetes platform with:

- **3 EKS clusters** across 3 regions — clear separation of concerns
- **Self-hosted GitHub Actions runners** inside the security cluster (no third-party CI access to AWS)
- **GitOps pipeline** driven by GitHub PRs — no manual `terragrunt apply` once set up
- **Security gates** at every step: secret scanning, IaC scanning, container scanning, policy enforcement
- **Ephemeral dev environments** — created on merge to `dev`, destroyed on merge to `main`
- **Centralised vulnerability management** — every scan feeds into DefectDojo
- **IRSA everywhere** — pods get AWS credentials through OIDC, no static keys
- **Cost-aware NAT** with [fck-nat](https://github.com/AndrewGuenther/fck-nat) instead of $32/month NAT Gateways

---

## Architecture

```text
┌─────────────────────────────────────────────────────────────────────────┐
│                                                                         │
│   Paris (eu-west-3)              Ireland (eu-west-1)     Frankfurt      │
│   ─────────────────              ─────────────────       (eu-central-1) │
│   security-eks (PERMANENT)       dev-eks (EPHEMERAL)     prod-eks       │
│                                                          (PERMANENT)    │
│   ┌─────────────────────┐        ┌─────────────────┐                    │
│   │ SonarQube           │        │ Test workloads  │     ┌──────────┐   │
│   │ DefectDojo          │  scan  │ created by PR   │ →   │ Real     │   │
│   │ Dependency Track    │ ────►  │ destroyed on    │ ──► │ services │   │
│   │ Vault               │        │ merge to main   │     │          │   │
│   │ Harbor              │        └─────────────────┘     └──────────┘   │
│   │ Prometheus+Grafana  │                                                │
│   │ Atlantis            │                                                │
│   │ GitHub Runner (ARC) │                                                │
│   └─────────────────────┘                                                │
│                                                                         │
└─────────────────────────────────────────────────────────────────────────┘

         ▲                                ▲                         ▲
         │                                │                         │
         └──── runs CI workflows ─────────┴──── deployed by ────────┘
                                                  GitOps
```

### Why 3 regions?

| Region | Purpose | Why this region |
|--------|---------|-----------------|
| `eu-west-3` (Paris) | Security tooling — permanent | Central scanning, separate blast radius |
| `eu-west-1` (Ireland) | Ephemeral dev — short-lived | Lots of capacity, fast spin-up |
| `eu-central-1` (Frankfurt) | Production workloads — permanent | Low-latency for EU users |

---

## The GitOps flow

```text
┌──────────────┐
│   Developer  │
│ feature/xyz  │
└──────┬───────┘
       │ git push
       ▼
┌──────────────────────────────────────┐
│ PR  feature/xyz  →  dev              │
├──────────────────────────────────────┤
│  • Security Scan workflow runs       │
│    - TruffleHog (secrets)            │
│    - KICS (IaC)                      │
│    - Checkov (IaC)                   │
│    - findings ➜ DefectDojo           │
│  • PR Checks workflow runs           │
│    - terragrunt fmt/validate/plan    │
│    - OPA/Conftest policies           │
│    - SonarQube SAST                  │
│    - Trivy scan                      │
│    - findings ➜ DefectDojo           │
└──────────────┬───────────────────────┘
               │ ✅ reviewer approves
               │ merge
               ▼
┌──────────────────────────────────────┐
│ push  →  dev                         │
├──────────────────────────────────────┤
│  Deploy Dev workflow                 │
│    1. assume AWS role via OIDC       │
│    2. terragrunt apply environments/dev
│    3. smoke tests                    │
│    → Cluster dev (Ireland) is up     │
└──────────────┬───────────────────────┘
               │ Manual testing in dev
               │ (kubectl, integration tests, ...)
               ▼
┌──────────────────────────────────────┐
│ PR  dev  →  main                     │
├──────────────────────────────────────┤
│  • Same scans rerun against final    │
│    state                             │
│  • Reviewer approves                 │
│  • Merge                             │
└──────────────┬───────────────────────┘
               │ pull_request closed + merged
               ▼
┌──────────────────────────────────────┐
│ Deploy Prod workflow                 │
├──────────────────────────────────────┤
│  Job 1: destroy-dev                  │
│    terragrunt destroy environments/dev
│    (dev was just for validation)     │
│                                      │
│  Job 2: deploy-prod                  │
│    ⚠ environment: production         │
│    (manual approval gate)            │
│    terragrunt apply environments/prod│
│    → Prod (Frankfurt) updated        │
└──────────────────────────────────────┘
```

### Why dev is ephemeral

Two reasons:

1. **Cost** — running dev 24/7 doubles your bill. Spin it up only when needed.
2. **State hygiene** — every PR gets a fresh cluster. No "works on my dev" because
   the dev was tweaked by hand three releases ago.

The trade-off: if multiple PRs are in flight, they queue (only one dev at a time
in this repo). For multi-team scale, see the [Roadmap](#roadmap) section about
preview environments per PR.

---

## Tech stack

| Layer | Tool | Why |
|-------|------|-----|
| IaC | Terraform 1.9 + Terragrunt 1.0 | Module reuse, remote state, dependencies |
| State | S3 + DynamoDB lock | Standard AWS pattern |
| Orchestration | EKS 1.31 | Managed Kubernetes |
| NAT | [fck-nat](https://github.com/AndrewGuenther/fck-nat) | $3/mo instead of $32/mo for NAT Gateway |
| Ingress | AWS Load Balancer Controller | Native ALB/NLB integration |
| Storage | EBS CSI driver | Persistent volumes for stateful tools |
| Cluster auth | EKS Access Entries (API mode) | Replaces deprecated aws-auth ConfigMap |
| Workload auth | IRSA (OIDC) | No static keys in pods |
| SAST | SonarQube | Code quality + security |
| IaC scan | KICS + Checkov | Two scanners cover different rule sets |
| Secret scan | TruffleHog | Verified-only mode, low false positives |
| Container scan | Trivy | Filesystem + image scanning |
| Policy | OPA + Conftest | Reusable policies tested in CI |
| Vuln mgmt | DefectDojo | Aggregates findings from all scanners |
| SCA | Dependency Track | Component analysis |
| Secrets | Vault | Dynamic credentials, encryption-as-a-service |
| Registry | Harbor | Private container registry with Trivy built-in |
| Observability | kube-prometheus-stack | Prometheus + Grafana + Alertmanager |
| PR automation | Atlantis | Terraform apply via PR comments |
| Runners | Actions Runner Controller | Self-hosted runners as K8s pods |

---

## Repository layout

```text
.
├── bootstrap/                        # One-time setup: S3 backends, DynamoDB, GitHub OIDC
│   ├── main.tf
│   ├── variables.tf
│   ├── terraform.tfvars.example      # Copy to terraform.tfvars and set github_repo
│   └── outputs.tf
├── environments/
│   ├── root.hcl                      # Shared terragrunt config (backend, provider)
│   ├── dev/                          # Ireland — ephemeral
│   │   ├── networking/terragrunt.hcl
│   │   ├── eks/terragrunt.hcl
│   │   └── eks-addons/terragrunt.hcl
│   ├── prod/                         # Frankfurt — permanent
│   │   ├── networking/
│   │   ├── eks/
│   │   ├── eks-addons/
│   │   └── prod-services/
│   └── security/                     # Paris — permanent
│       ├── networking/
│       ├── eks/
│       ├── eks-addons/
│       └── security-tools/
├── modules/
│   ├── networking/                   # VPC, subnets, IGW, fck-nat, flow logs
│   ├── eks/                          # Cluster, node group, OIDC provider, access entries
│   ├── eks-addons/                   # EBS CSI, CoreDNS, kube-proxy, LBC + IRSA
│   ├── security-tools/               # IRSA roles + Harbor S3 + KMS
│   └── prod-services/                # Generic IRSA role for prod apps
├── kubernetes/
│   ├── namespaces/                   # security-tools, dev-services, prod-services
│   ├── helm/                         # values.yaml for each tool
│   └── manifests/                    # github-runner, ingresses, network policies
├── policies/                         # OPA/Rego policies (run by Conftest)
│   ├── *.rego
│   └── tests/
├── scripts/
│   └── smoke-tests.sh                # Post-deploy validation
├── .github/
│   ├── workflows/
│   │   ├── security-scan.yaml        # Runs on PR open
│   │   ├── pr-checks.yaml            # Runs on PR open (terraform validate/plan)
│   │   ├── deploy-dev.yaml           # Runs on push to dev (after PR merge)
│   │   └── deploy-prod.yaml          # Runs on PR merge to main
│   └── CODEOWNERS
├── README.md
├── SETUP.md                          # Step-by-step setup guide
├── Makefile
└── LICENSE
```

---

## Quick start

> **Full instructions** with copy-paste commands, troubleshooting, and screenshots are
> in **[SETUP.md](SETUP.md)**. The below is a high-level summary.

1. **Fork** this repo to your GitHub account.
2. **Configure AWS** (paid account; Free Plan strict won't allow `t3.large`).
3. **Bootstrap**:
   ```bash
   cd bootstrap
   cp terraform.tfvars.example terraform.tfvars   # set github_repo = "you/your-fork"
   terraform init && terraform apply
   ```
4. **Deploy permanent clusters** (security + prod, ~25 min each):
   ```bash
   terragrunt run --all apply --working-dir environments/security
   terragrunt run --all apply --working-dir environments/prod
   ```
5. **Install security tools** (Helm) — see [SETUP.md §6](SETUP.md).
6. **Configure GitHub** — secrets, environments, branch protection.
7. **Try the flow**: branch off, open PR to `dev`, watch the magic.

---

## How a developer uses this

Day-to-day, a developer only ever does this:

```bash
# 1. Branch off main
git checkout -b feature/add-service-x

# 2. Make changes (e.g. add a new IAM role in modules/prod-services/main.tf)
$EDITOR modules/prod-services/main.tf

# 3. Push and open PR to dev
git push origin feature/add-service-x
gh pr create --base dev --head feature/add-service-x

# 4. Wait for green checks (scans + plan + policies)
# 5. Approve & merge → dev cluster gets created automatically with the change
# 6. Test manually in dev (kubectl, curl, etc.)
# 7. If happy, open PR dev → main, approve, merge
# 8. Prod gets updated, dev gets destroyed automatically
```

That's it. No `terraform apply` from anyone's laptop. Ever.

---

## Security controls

### At-rest

- **S3 state buckets**: KMS-encrypted, versioning, public access blocked
- **DynamoDB locks**: server-side encryption
- **EKS secrets**: optional KMS envelope encryption (opt-in to avoid recreating existing clusters)
- **EBS volumes**: encrypted by default via launch template

### In-transit

- **EKS API endpoint**: private + public with configurable CIDR allowlist (default open for PoC; restrict per env)
- **All workloads**: traffic stays in VPC unless explicitly routed out via fck-nat

### Access

- **IRSA** for every pod that needs AWS access — no instance-profile shortcuts, no static keys
- **OIDC trust** scoped to specific GitHub repo (`repo:owner/repo:*`) for GitHub Actions
- **EKS Access Entries** in API mode (no aws-auth ConfigMap drift)
- **CODEOWNERS** + branch protection forces human review for every change

### Audit & observability

- **VPC flow logs** to CloudWatch (7-day retention by default)
- **EKS control plane logs** (api, audit, authenticator, controllerManager, scheduler)
- **Prometheus** scraping all clusters
- **DefectDojo** as single pane of glass for findings across scanners

### CI/CD security

- Self-hosted runners in **private subnets** inside the security cluster
- **No third-party CI service** holds AWS credentials
- GitHub OIDC → AWS STS → assume role (short-lived credentials)
- PRs to `main` require approving review from `@hallllow29` (or configured CODEOWNER)

---

## OPA policies enforced

Run by Conftest in `pr-checks.yaml`:

| Policy | What it blocks |
|--------|----------------|
| `no_public_s3` | S3 buckets without `PublicAccessBlock` |
| `enforce_imdsv2` | EC2 instances allowing IMDSv1 |
| `require_encryption` | EBS volumes without encryption |
| `eks_private_endpoint` | EKS clusters without `endpoint_private_access` |
| `no_privileged_containers` | Privileged pods |
| `require_tags` | Resources without `Name` and `Environment` tags |
| `no_wide_ingress` | Security groups with SSH open to `0.0.0.0/0` |
| `eks_secrets_encryption` | EKS clusters without KMS encryption |

Each policy has a corresponding test in `policies/tests/`.

---

## Cost

Running everything 24/7 (all 3 clusters up):

| Resource | $/month |
|----------|---------|
| 3× EKS control plane ($0.10/h × 730h) | $216 |
| 6× t3.large SPOT nodes | ~$130 |
| ALBs (1 per exposed workload) | $20–60 |
| EBS volumes (PVCs for stateful tools) | ~$20 |
| 3× fck-nat (t4g.nano) | ~$5 |
| S3 + KMS + DynamoDB + CloudWatch logs | ~$10 |
| **Total** | **~$400–500** |

**Cost-saving notes**:

- Dev is ephemeral — only pays during testing windows. Realistic monthly: **~$350**.
- All node groups use SPOT instances (~70% cheaper than on-demand).
- Replace fck-nat with NAT Gateway only if you need 99.99% NAT uptime.
- For learning/portfolio: spin up, capture screenshots, destroy. ~$15 one-off.

See `docs/COST.md` for a detailed optimisation matrix (Fargate, Karpenter, instance
type choices, etc.).

---

## Customisation

### Adding a new application to production

1. Add Terraform IAM role and dependencies in `modules/prod-services/`.
2. Add Helm chart values in `kubernetes/helm/<your-app>/`.
3. Add Kubernetes manifests in `kubernetes/manifests/prod-services/`.
4. Open PR to `dev` — scans run, dev gets the change, test, then PR to `main`.

### Tuning node sizing per environment

Override in the env's `eks/terragrunt.hcl`:

```hcl
inputs = {
  environment    = "prod"
  instance_types = ["t3.xlarge"]   # default is t3.large
  desired_size   = 4
  max_size       = 8
  min_size       = 2
}
```

### Restricting the EKS endpoint CIDR

```hcl
inputs = {
  endpoint_public_access_cidrs = ["<YOUR_OFFICE_CIDR>/32"]
}
```

### Enabling EKS secrets encryption (new clusters only — opt-in to avoid recreate)

```hcl
inputs = {
  enable_secrets_encryption = true
}
```

---

## Roadmap

- [ ] **Preview environments per PR** — `dev-pr-<number>` instead of single shared dev
- [ ] **Karpenter** for node autoscaling (replace fixed ASG)
- [ ] **ArgoCD** as the source of truth for Kubernetes manifests
- [ ] **External DNS** for Route53 automation
- [ ] **cert-manager** with Let's Encrypt for public TLS
- [ ] **Slack alert routing** in Alertmanager
- [ ] **Custom runner image** with `awscli`, `kubectl`, `helm`, `jq` pre-installed
- [ ] **Terratest** module tests
- [ ] **Renovate / Dependabot** for Helm chart and module updates
- [ ] **Cost dashboard** with AWS Cost Explorer integration
- [ ] **Disaster recovery runbook** in `docs/DR.md`

---

## Troubleshooting

See `docs/TROUBLESHOOTING.md` for solutions to common issues:

- `terragrunt run --all apply` failing with state-checksum mismatch
- IAM roles surviving after partial destroy ("EntityAlreadyExists")
- EKS Access Entry rejecting assumed-role ARNs
- Self-hosted runner stuck in `Pending`
- Helm release `cannot re-use a name that is still in use`
- DefectDojo returning HTML on `/api/v2/import-scan/` (ALLOWED_HOSTS)

---

## Contributing

PRs welcome. The flow this repo demonstrates is also the flow used to develop it:

1. Branch off `main`
2. PR to `dev` — scans must pass, reviewer approves
3. Merge → dev cluster validates the change
4. PR `dev` → `main` — final review
5. Merge → prod updated, dev torn down

See `CONTRIBUTING.md` for code style and commit message conventions.

---

## License

MIT — use, modify, distribute. See [LICENSE](LICENSE).

---

## Acknowledgements

- [fck-nat](https://github.com/AndrewGuenther/fck-nat) by Andrew Guenther — the $32/month NAT Gateway killer
- [DefectDojo](https://www.defectdojo.com/) — vulnerability management done right
- [Atlantis](https://www.runatlantis.io/) — for showing that Terraform deserves PR-driven workflows
- [SonarSource](https://www.sonarsource.com/), [Checkmarx KICS](https://kics.io/), [Bridgecrew Checkov](https://www.checkov.io/), [Aqua Trivy](https://trivy.dev/) — for free, open-source scanners
