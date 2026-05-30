# Setup Guide

Guia passo-a-passo para clonar este projeto e ter um ambiente GitOps DevSecOps funcional na AWS.

## Pré-requisitos

| Ferramenta | Versão | Notas |
|---|---|---|
| AWS account | — | Conta paga (não Free Plan strict — t3.large não está no Free Tier) |
| AWS CLI | 2.x | Configurado com user IAM com `AdministratorAccess` |
| Terraform | >= 1.9.0 | |
| Terragrunt | >= 1.0.6 | Não a versão 0.x — sintaxe mudou |
| kubectl | >= 1.31 | |
| Helm | >= 3.x | |
| GitHub account | — | Com repo público ou privado |
| GitHub PAT | fine-grained | Permissions: Actions r/w, Administration r/w sobre o repo |

Custos estimados (ambientes UP):
- 3 EKS control planes: ~$0.30/h
- 6 nodes (2 t3.large SPOT em cada cluster): ~$0.18/h
- ALBs/NAT/etc: ~$0.05/h
- **Total ~$0.55/h** (~$13/dia, ~$400/mês)

## 1. Fork e clone

```bash
git clone https://github.com/YOUR_GITHUB_USER/gitops-devsecops-aws
cd gitops-devsecops-aws
```

## 2. Configurar AWS

```bash
aws configure
# Region default sugerida: eu-central-1 (prod)
```

## 3. Bootstrap (S3 backends, DynamoDB, GitHub OIDC)

```bash
cd bootstrap
cp terraform.tfvars.example terraform.tfvars
# Edita terraform.tfvars e coloca o teu github_repo (formato owner/repo)
terraform init
terraform apply
cd ..
```

Outputs importantes:
- `aws_iam_role.github_actions` ARN — vai ser usado como GitHub Secret `AWS_ROLE_ARN`

## 4. Deploy do cluster security (Paris, eu-west-3) — PERMANENTE

```bash
terragrunt run --all apply --working-dir environments/security --non-interactive
```

Demora ~25 min. Cria VPC + EKS + addons + IAM roles + S3 Harbor + KMS.

Cria access entry (kubectl funciona):

```bash
aws eks update-kubeconfig --name security-eks --region eu-west-3 --alias security
```

## 5. Deploy do cluster prod (Frankfurt, eu-central-1) — PERMANENTE

```bash
terragrunt run --all apply --working-dir environments/prod --non-interactive
```

> Nota: o cluster `dev` (Ireland) é **ephemeral**, criado pelo workflow GitOps quando se faz merge para a branch `dev`. **Não criar manualmente**.

## 6. Instalar Helm charts no security (security tools)

```bash
kubectl config use-context security

# Pré-requisitos
helm repo add jetstack https://charts.jetstack.io
helm repo add sonarqube https://SonarSource.github.io/helm-chart-sonarqube
helm repo add hashicorp https://helm.releases.hashicorp.com
helm repo add harbor https://helm.goharbor.io
helm repo add dependency-track https://dependencytrack.github.io/helm-charts
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo add runatlantis https://runatlantis.github.io/helm-charts
helm repo add actions-runner-controller https://actions-runner-controller.github.io/actions-runner-controller
helm repo update

# Cert manager (pré-req do ARC)
helm install cert-manager jetstack/cert-manager -n cert-manager --create-namespace --set installCRDs=true --wait

# Namespace
kubectl apply -f kubernetes/namespaces/security-tools.yaml

# Pegar ARNs das roles IRSA
SONAR_ROLE=$(aws iam get-role --role-name security-sonarqube-role --query "Role.Arn" --output text)
HARBOR_ROLE=$(aws iam get-role --role-name security-harbor-role --query "Role.Arn" --output text)
VAULT_ROLE=$(aws iam get-role --role-name security-vault-role --query "Role.Arn" --output text)

# StorageClass default (necessário para PVCs)
kubectl annotate storageclass gp2 storageclass.kubernetes.io/is-default-class=true

# SonarQube
helm install sonarqube sonarqube/sonarqube -n security-tools \
  --set serviceAccount.annotations."eks\.amazonaws\.com/role-arn"="$SONAR_ROLE" \
  --set persistence.storageClass=gp2 \
  --set monitoringPasscode="CHANGE_ME_PASSCODE" \
  --set community.enabled=true \
  --wait --timeout 15m

# Vault
helm install vault hashicorp/vault -n security-tools \
  --set "server.serviceAccount.annotations.eks\.amazonaws\.com/role-arn=$VAULT_ROLE" \
  --set server.ha.enabled=false \
  --set server.dataStorage.storageClass=gp2 \
  --wait --timeout 10m

# Dependency Track (api server requer 1 vCPU para t3.large)
helm install dtrack dependency-track/dependency-track -n security-tools \
  --set apiServer.persistentVolume.storageClass=gp2 \
  --set "apiServer.resources.requests.cpu=1000m" \
  --set "apiServer.resources.requests.memory=4Gi" \
  --set "apiServer.resources.limits.cpu=1500m" \
  --set "apiServer.resources.limits.memory=5Gi" \
  --wait --timeout 15m

# Prometheus + Grafana
helm install monitoring prometheus-community/kube-prometheus-stack -n security-tools \
  --set prometheus.prometheusSpec.storageSpec.volumeClaimTemplate.spec.storageClassName=gp2 \
  --set grafana.persistence.enabled=true \
  --set grafana.persistence.storageClassName=gp2 \
  --set grafana.adminPassword="CHANGE_ME" \
  --wait --timeout 15m

# Atlantis (idle até configurares webhook)
helm install atlantis runatlantis/atlantis -n security-tools \
  --set "github.user=YOUR_GITHUB_USER" \
  --set "github.token=PLACEHOLDER" \
  --set "github.secret=PLACEHOLDER" \
  --set "orgAllowlist=github.com/YOUR_GITHUB_USER/*" \
  --set "volumeClaim.storageClassName=gp2" \
  --wait --timeout 10m

# Harbor
helm install harbor harbor/harbor -n security-tools \
  --set "harborAdminPassword=CHANGE_ME" \
  --set "expose.type=clusterIP" \
  --set "expose.tls.enabled=false" \
  --set "persistence.persistentVolumeClaim.registry.storageClass=gp2" \
  --set "persistence.persistentVolumeClaim.jobservice.jobLog.storageClass=gp2" \
  --set "persistence.persistentVolumeClaim.database.storageClass=gp2" \
  --set "persistence.persistentVolumeClaim.redis.storageClass=gp2" \
  --set "persistence.persistentVolumeClaim.trivy.storageClass=gp2" \
  --wait --timeout 15m

# DefectDojo (chart vive no repo do projeto)
cd /tmp
git clone --depth 1 https://github.com/DefectDojo/django-DefectDojo
cd django-DefectDojo
helm dependency update ./helm/defectdojo
helm install defectdojo ./helm/defectdojo -n security-tools \
  --set "django.ingress.enabled=false" \
  --set "host=defectdojo.local" \
  --set "createSecret=true" \
  --set "createPostgresqlSecret=true" \
  --set "createValkeySecret=true" \
  --wait --timeout 25m

# Permitir acesso ao DefectDojo via SVC interno (pipeline + port-forward)
kubectl set env deployment/defectdojo-django -n security-tools \
  DD_ALLOWED_HOSTS="localhost,defectdojo.local,127.0.0.1,defectdojo-django,defectdojo-django.security-tools,defectdojo-django.security-tools.svc.cluster.local,*" \
  DD_CSRF_TRUSTED_ORIGINS="http://localhost:8080,http://defectdojo.local:8080,http://127.0.0.1:8080"
kubectl rollout status deployment/defectdojo-django -n security-tools
```

## 7. Setup do GitHub Self-Hosted Runner (ARC)

Cria um **GitHub PAT** com permissions:
- Actions: Read and write
- Administration: Read and write

```bash
read -s -p "Cola o GitHub PAT: " GITHUB_PAT
kubectl create namespace actions-runner-system
kubectl create secret generic controller-manager -n actions-runner-system \
  --from-literal=github_token=$GITHUB_PAT
unset GITHUB_PAT

helm install actions-runner-controller actions-runner-controller/actions-runner-controller \
  --namespace actions-runner-system --wait --timeout 5m

# Editar kubernetes/manifests/security-tools/github-runner.yaml: substitui YOUR_GITHUB_USER/gitops-devsecops-aws
kubectl apply -f kubernetes/manifests/security-tools/github-runner.yaml

# Validar
kubectl get runners -n security-tools
```

## 8. GitHub Secrets

Em `Settings → Secrets and variables → Actions`, adicionar:

| Secret | Valor |
|---|---|
| `AWS_ROLE_ARN` | ARN do `github-actions-role` criado pelo bootstrap |
| `SONAR_TOKEN` | Token gerado no SonarQube (Profile → Security → Generate Token) |
| `SONAR_HOST_URL` | `http://sonarqube-sonarqube.security-tools.svc.cluster.local:9000` |
| `DEFECTDOJO_TOKEN` | API token do DefectDojo (Profile → API v2 Key → Generate) |
| `DEFECTDOJO_URL` | `defectdojo-django.security-tools.svc.cluster.local` |
| `SLACK_WEBHOOK` | (opcional) URL do webhook Slack para notificações |

## 9. GitHub Environments

Em `Settings → Environments`, criar:
- `dev-approval` → Required reviewers: o teu user (gate para Deploy Dev)
- `production` → Required reviewers: o teu user (gate para Deploy Prod)

## 10. Branch Protection

Em `Settings → Rules → Rulesets → New ruleset`:

- Target: `main`
- Require pull request before merging (1 approval)
- Require status checks: `security-scan`, `pr-checks`
- Require review from Code Owners
- Block force pushes
- Do not allow bypassing

## 11. Flow GitOps em uso

```text
feature branch    →    PR para dev    →    [security-scan + pr-checks]
                                                      ↓ approve
                                                    merge
                                                      ↓
                                          [Deploy Dev workflow]
                                                      ↓
                                            Cluster dev (Ireland) UP
                                            ↓ testes manuais
                                                      ↓
dev branch        →    PR para main   →    [security-scan + pr-checks]
                                                      ↓ approve
                                                    merge
                                                      ↓
                                          [Deploy Prod workflow]
                                          ├─ destroy dev
                                          └─ deploy prod (Frankfurt)
```

## 12. Tear down (apagar tudo)

```bash
terragrunt run --all destroy --working-dir environments/dev --non-interactive
terragrunt run --all destroy --working-dir environments/prod --non-interactive
terragrunt run --all destroy --working-dir environments/security --non-interactive

cd bootstrap
# Esvaziar buckets S3 antes (têm versioning)
# ver scripts/cleanup.sh
terraform destroy
```

## Troubleshooting

### "BucketRegionError" no terragrunt
O `root.hcl` força region `eu-central-1` no remote_state. Se mudaste isso, ajusta.

### "EntityAlreadyExists" em IAM roles
Sobras de runs anteriores. Apaga manualmente:
```bash
aws iam delete-role --role-name <ROLE>
```

### Workflows não disparam
- Confirma branch protection não bloqueia a branch destino
- Confirma o ficheiro `.github/workflows/*.yaml` está na branch que está a fazer push

### Runner offline
```bash
kubectl get pods -n security-tools | grep runner
kubectl logs -n actions-runner-system deployment/actions-runner-controller
```

Se o token expirou, regenera o PAT, atualiza o secret e:
```bash
kubectl rollout restart deployment/actions-runner-controller -n actions-runner-system
kubectl rollout restart deployment/gitops-runner -n security-tools
```
