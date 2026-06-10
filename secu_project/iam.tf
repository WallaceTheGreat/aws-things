# PILIER 1 — IAM : roles et moindre privilege

# Cle KMS : chiffrement centralise (partagee entre tous les piliers)
resource "aws_kms_key" "main" {
  description         = "Cle principale securite application"
  enable_key_rotation = true
  tags                = { ManagedBy = "terraform" }
}

resource "aws_kms_alias" "main" {
  name          = "alias/app-securisee"
  target_key_id = aws_kms_key.main.key_id
}

# Role : application backend (acces DynamoDB + S3 limite)
resource "aws_iam_role" "app_role" {
  name = "app-backend-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "lambda.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy" "app_policy" {
  name = "app-backend-policy"
  role = aws_iam_role.app_role.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["dynamodb:GetItem", "dynamodb:PutItem", "dynamodb:Query"]
        Resource = "arn:aws:dynamodb:*:*:table/baas-*"
      },
      {
        Effect   = "Allow"
        Action   = ["s3:GetObject", "s3:PutObject"]
        Resource = ["arn:aws:s3:::app-files-*", "arn:aws:s3:::app-files-*/*"]
      },
      {
        Effect   = "Allow"
        Action   = ["logs:CreateLogGroup", "logs:PutLogEvents", "logs:CreateLogStream"]
        Resource = "arn:aws:logs:*:*:log-group:/app/*"
      },
      {
        Effect   = "Allow"
        Action   = ["kms:Decrypt", "kms:GenerateDataKey"]
        Resource = aws_kms_key.main.arn
      },
      {
        Sid      = "DenyAdmin"
        Effect   = "Deny"
        Action   = ["iam:*", "s3:DeleteBucket", "dynamodb:DeleteTable", "kms:DeleteKey"]
        Resource = "*"
      }
    ]
  })
}
