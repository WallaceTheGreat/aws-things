# 1. Zipper la fonction (Terraform le fait automatiquement)
data "archive_file" "lambda_zip" {
  type        = "zip"
  source_file = "handler.py"
  output_path = "lambda.zip"
}

# 2. Role IAM pour la Lambda (moindre privilege)
resource "aws_iam_role" "lambda_role" {
  name = "faas-lambda-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "lambda.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

# 3. Policy : ecriture logs seulement
resource "aws_iam_role_policy" "lambda_logs" {
  name = "lambda-logs-policy"
  role = aws_iam_role.lambda_role.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = ["logs:CreateLogGroup", "logs:CreateLogStream", "logs:PutLogEvents"]
      Resource = "arn:aws:logs:*:*:*"
    }]
  })
}

# 4. La fonction Lambda
resource "aws_lambda_function" "ma_fonction" {
  function_name    = "faas-demo"
  filename         = data.archive_file.lambda_zip.output_path
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256
  runtime          = "python3.12"
  handler          = "handler.handler"
  role             = aws_iam_role.lambda_role.arn
  timeout          = 30
  memory_size      = 128

  environment {
    variables = { ENVIRONNEMENT = "localstack-dev" }
  }
}

# 5. Trigger S3 : la Lambda se declenche quand un fichier est uploade
resource "aws_s3_bucket" "trigger_bucket" {
  bucket = "faas-trigger-bucket"
}

# Permission : autoriser S3 a invoquer la Lambda
resource "aws_lambda_permission" "allow_s3" {
  statement_id  = "AllowS3Invoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.ma_fonction.function_name
  principal     = "s3.amazonaws.com"
  source_arn    = aws_s3_bucket.trigger_bucket.arn
}

resource "aws_s3_bucket_notification" "trigger" {
  bucket = aws_s3_bucket.trigger_bucket.id

  lambda_function {
    lambda_function_arn = aws_lambda_function.ma_fonction.arn
    events              = ["s3:ObjectCreated:*"]
  }

  depends_on = [aws_lambda_permission.allow_s3]
}
