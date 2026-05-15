resource "aws_s3_bucket" "state" {
  for_each = var.regions
  bucket = "gitops-state-${each.key}"

  tags = {
    Name        = "gitops-state-${each.key}"
    Environment = each.key
  }
}

resource "aws_s3_bucket_versioning" "state" {
  for_each = var.regions
  bucket = aws_s3_bucket.state[each.key].id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_kms_key" "tf-state-key" {
  description             = "This key is used to encrypt bucket objects"
  deletion_window_in_days = 10
}

resource "aws_s3_bucket_public_access_block" "state" {
  for_each = var.regions
  bucket = aws_s3_bucket.state[each.key].id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "state" {
  for_each = var.regions
  bucket   = aws_s3_bucket.state[each.key].id

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = aws_kms_key.tf-state-key.arn
      sse_algorithm     = "aws:kms"
    }
  }
}

resource "aws_dynamodb_table" "state" {
    name           = "gitops-lock-${each.key}"
    for_each = var.regions
    billing_mode = "PAY_PER_REQUEST"
    hash_key       = "LockID"
    attribute {
        name = "LockID"
        type = "S"
    }
    tags = {
        "Name" = "DynamoDB Terraform State Lock Table"
    }
}