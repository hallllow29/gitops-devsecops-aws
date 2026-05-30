# Runbook — Promote to Production

How to promote changes from dev to production.

## Prerequisites

- Changes merged to `main`
- Dev environment deployed and tested
- Required approvals obtained

## Steps

### 1. Verify dev environment

```bash
make kubeconfig-dev
kubectl get pods -A
```

### 2. Run manual tests

Test your changes in Ireland before promoting.
Document what you tested and the results.

### 3. Approve dev deployment

Go to GitHub Actions → Deploy Dev → Review deployments → Approve

### 4. Trigger production deployment

Go to GitHub Actions → Deploy Prod → Run workflow

### 5. Approve production deployment

When prompted, review and approve the production deployment.

### 6. Verify production

```bash
make kubeconfig-prod
kubectl get pods -A
```

### 7. Monitor

Check Grafana in Paris for any anomalies after deployment:

```bash
kubectl port-forward svc/prometheus-grafana 3000:80 -n security-tools
```

Open <http://localhost:3000>

## Rollback

If something goes wrong in production:

```bash
# Option 1 — Revert the commit and push to dev
git revert HEAD
git push origin dev

# Option 2 — Manual rollback via Helm
helm rollback YOUR_RELEASE -n prod-services

# Option 3 — Destroy and redeploy previous version
make down-prod
git checkout PREVIOUS_COMMIT
make up-prod
```
