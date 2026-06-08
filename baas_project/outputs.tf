output "users_table_name" {
  value = aws_dynamodb_table.users.name
}

output "sessions_table_name" {
  value = aws_dynamodb_table.sessions.name
}

output "user_files_bucket" {
  value = aws_s3_bucket.user_files.bucket
}

output "baas_user_arn" {
  value = aws_iam_user.baas_app.arn
}
