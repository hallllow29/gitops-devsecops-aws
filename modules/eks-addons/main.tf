data "aws_caller_identity" "current" {}

data "http" "lbc_policy" {
  url = "https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/main/docs/install/iam_policy.json"
}

resource "aws_eks_addon" "ebs_csi_driver" {
  cluster_name  = var.cluster_name
  addon_name    = "aws-ebs-csi-driver"
  addon_version = var.addon_versions["ebs_csi_driver"]
}

resource "aws_eks_addon" "coredns" {
  cluster_name  = var.cluster_name
  addon_name    = "coredns"
  addon_version = var.addon_versions["coredns"]
}

resource "aws_eks_addon" "kube-proxy" {
  cluster_name  = var.cluster_name
  addon_name    = "kube-proxy"
  addon_version = var.addon_versions["kube_proxy"]
}

resource "aws_iam_role" "lbc" {
  name = "${var.environment}-lbc-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRoleWithWebIdentity"
        Effect = "Allow"
        Principal = {
          Federated = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:oidc-provider/${var.oidc_issuer_url}"
        }
      }
    ]
  })

  tags = {
    Name        = "${var.environment}-lbc-role"
    Environment = var.environment
  }
}

resource "aws_iam_policy" "lbc" {
  name        = "${var.environment}-lbc-policy"
  description = "IAM policy for AWS Load Balancer Controller"
  policy      = data.http.lbc_policy.response_body
}

resource "aws_iam_role_policy_attachment" "lbc" {
  policy_arn = aws_iam_policy.lbc.arn
  role       = aws_iam_role.lbc.name
}
