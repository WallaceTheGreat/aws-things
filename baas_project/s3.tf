resource "aws_s3_bucket" "user_files" {
  bucket = "baas-user-files"
}

resource "aws_s3_bucket_versioning" "user_files" {
  bucket = aws_s3_bucket.user_files.id
  versioning_configuration {
    status = "Enabled"
  }
}
