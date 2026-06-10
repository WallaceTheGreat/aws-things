# PILIER 2 — Chiffrement en transit et au repos

resource "aws_s3_bucket" "app_files" {
  bucket = "app-files-securises"
}

resource "aws_s3_bucket_public_access_block" "app_files" {
  bucket                  = aws_s3_bucket.app_files.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "app_files" {
  bucket = aws_s3_bucket.app_files.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = aws_kms_key.main.arn
    }
  }
}

# Policy HTTPS uniquement (chiffrement en transit)
resource "aws_s3_bucket_policy" "force_https" {
  bucket = aws_s3_bucket.app_files.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Deny"
      Principal = "*"
      Action    = "s3:*"
      Resource = [
        aws_s3_bucket.app_files.arn,
        "${aws_s3_bucket.app_files.arn}/*"
      ]
      Condition = { Bool = { "aws:SecureTransport" = "false" } }
    }]
  })
  depends_on = [aws_s3_bucket_public_access_block.app_files]
}
