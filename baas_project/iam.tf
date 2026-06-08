resource "aws_iam_user" "baas_app" {
  name = "baas-app-user"
  tags = { Service = "BaaS", ManagedBy = "terraform" }
}

resource "aws_iam_policy" "baas_policy" {
  name        = "baas-app-policy"
  description = "Acces DynamoDB et S3 pour l'application BaaS"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "dynamodb:PutItem",
          "dynamodb:GetItem",
          "dynamodb:UpdateItem",
          "dynamodb:DeleteItem",
          "dynamodb:Scan",
          "dynamodb:Query"
        ]
        Resource = [
          aws_dynamodb_table.users.arn,
          aws_dynamodb_table.sessions.arn
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "s3:PutObject",
          "s3:GetObject",
          "s3:DeleteObject",
          "s3:ListBucket"
        ]
        Resource = [
          aws_s3_bucket.user_files.arn,
          "${aws_s3_bucket.user_files.arn}/*"
        ]
      }
    ]
  })
}

resource "aws_iam_user_policy_attachment" "baas_app_attach" {
  user       = aws_iam_user.baas_app.name
  policy_arn = aws_iam_policy.baas_policy.arn
}
