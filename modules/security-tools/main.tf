data "aws_caller_identity" "current" {}

resource "aws_iam_role" "sonarqube" {
  name = "${var.environment}-sonarqube-role"

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
    Name        = "${var.environment}-sonarqube-role"
    Environment = var.environment
  }
}

resource "aws_iam_role" "harbor" {
  name = "${var.environment}-harbor-role"

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
    Name        = "${var.environment}-harbor-role"
    Environment = var.environment
  }
}

resource "aws_iam_role" "dtrack" {
  name = "${var.environment}-dtrack-role"

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
    Name        = "${var.environment}-dtrack-role"
    Environment = var.environment
  }
}

resource "aws_iam_role" "vault" {
  name = "${var.environment}-vault-role"

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
    Name        = "${var.environment}-vault-role"
    Environment = var.environment
  }
}

resource "aws_iam_role" "prometheus" {
  name = "${var.environment}-prometheus-role"

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
    Name        = "${var.environment}-prometheus-role"
    Environment = var.environment
  }
}

resource "aws_iam_role" "atlantis" {
  name = "${var.environment}-atlantis-role"

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
    Name        = "${var.environment}-atlantis-role"
    Environment = var.environment
  }
}

resource "aws_iam_policy" "harbor" {
  name        = "${var.environment}-harbor-policy"
  description = "IAM policy for Harbor container registry S3 storage"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:ListBucket"
        ]
        Resource = [
          "arn:aws:s3:::${var.environment}-harbor-registry",
          "arn:aws:s3:::${var.environment}-harbor-registry/*"
        ]
      }
    ]
  })
}

resource "aws_s3_bucket" "harbor" {
  bucket = "${var.environment}-harbor-registry"

  tags = {
    Name        = "Harbor Bucket"
    Environment = var.environment
  }
}

resource "aws_s3_bucket_versioning" "harbor" {
  bucket = aws_s3_bucket.harbor.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_public_access_block" "harbor" {
  bucket = aws_s3_bucket.harbor.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "harbor" {
  bucket = aws_s3_bucket.harbor.id

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = aws_kms_key.harbor-key.arn
      sse_algorithm     = "aws:kms"
    }
  }
}

resource "aws_kms_key" "harbor-key" {
  description             = "This key is used to encrypt bucket objects"
  deletion_window_in_days = 10
}

resource "aws_iam_policy" "vault" {
  name        = "${var.environment}-vault-policy"
  description = "IAM policy for Vault - DynamoDB storage and KMS encryption"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "dynamodb:DescribeLimits",
          "dynamodb:DescribeTimeToLive",
          "dynamodb:ListTagsOfResource",
          "dynamodb:DescribeReservedCapacityOfferings",
          "dynamodb:DescribeReservedCapacity",
          "dynamodb:ListTables",
          "dynamodb:BatchWriteItem",
          "dynamodb:BatchGetItem",
          "dynamodb:DescribeTable",
          "dynamodb:DeleteItem",
          "dynamodb:GetItem",
          "dynamodb:PutItem",
          "dynamodb:Query",
          "dynamodb:UpdateItem"
        ]
        Resource = "arn:aws:dynamodb:*:${data.aws_caller_identity.current.account_id}:table/${var.environment}-vault"
      },
      {
        Effect = "Allow"
        Action = [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:DescribeKey"
        ]
        Resource = "arn:aws:kms:*:${data.aws_caller_identity.current.account_id}:key/*"
      }
    ]
  })
}


resource "aws_iam_role_policy_attachment" "prometheus" {
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchReadOnlyAccess"
  role       = aws_iam_role.prometheus.name
}

resource "aws_iam_role_policy_attachment" "harbor" {
  policy_arn = aws_iam_policy.harbor.arn
  role       = aws_iam_role.harbor.name
}

resource "aws_iam_role_policy_attachment" "vault" {
  policy_arn = aws_iam_policy.vault.arn
  role       = aws_iam_role.vault.name
}