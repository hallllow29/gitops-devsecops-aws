# Cost Estimate

## Monthly breakdown

### Always-on resources

| Resource                       | Region    | Type              | Cost/month      |
|--------------------------------|-----------|-------------------|----------------|
| EKS control plane              | Frankfurt | Managed           | ~$72           |
| EKS control plane              | Paris     | Managed           | ~$72           |
| EC2 nodes (2x t3.medium spot) | Frankfurt | Spot              | ~$20           |
| EC2 nodes (2x t3.medium spot) | Paris     | Spot              | ~$20           |
| EBS volumes (security tools)   | Paris     | gp2 50GB          | ~$5            |
| EBS volumes (prod)             | Frankfurt | gp2 20GB          | ~$2            |
| S3 buckets (state + Harbor)    | All       | Standard          | ~$3            |
| DynamoDB (state locking)       | All       | PAY_PER_REQUEST   | ~$1            |
| KMS keys                       | All       | Per key           | ~$3            |
| **Always-on total**            |           |                   | **~$198/month** |

### Ephemeral resources (Ireland)

| Resource                        | Type    | Cost/hour   |
|---------------------------------|---------|-------------|
| EKS control plane               | Managed | $0.10       |
| EC2 nodes (t3.medium spot)     | Spot    | ~$0.015     |
| **Total per hour**              |         | **~$0.115** |

Ireland only exists during testing. Cost depends on how long testing takes.
Typical session: 1-2 hours = ~$0.20 per deploy.

## Cost optimisation tips

### For learning and development

Stop EC2 nodes when not working:

```bash
# Scale down nodes to 0
aws eks update-nodegroup-config \
  --cluster-name security-eks \
  --nodegroup-name security-node-group \
  --scaling-config minSize=0,maxSize=2,desiredSize=0 \
  --region eu-west-3
```

Or destroy everything when done:

```bash
make down-all
```

### For production use

- Use Reserved Instances for always-on nodes (~40% savings)
- Use Savings Plans for EKS control plane (~20% savings)
- Set up AWS Budgets alerts to avoid surprise bills

## Free tier

The following resources are covered by AWS Free Tier (12 months):

- S3: 5GB storage
- DynamoDB: 25GB + 25 WCU/RCU
- Data transfer: 100GB out/month

> **Note:** EKS control plane and EC2 instances are NOT covered by free tier.
> Estimated minimum cost to run this project: ~$200/month always-on,
> or ~$5-10/month if you start/stop instances daily.