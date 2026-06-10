# Object Storage : S3 (simulation)
resource "aws_s3_bucket" "benchmark_object" {
  bucket = "benchmark-object-storage"
}

# Block Storage simule : EBS via instance EC2
resource "aws_ebs_volume" "benchmark_block" {
  availability_zone = "us-east-1a"
  size              = 10 # 10 Go pour le test
  type              = "gp3"

  tags = { Name = "benchmark-block-storage" }
}

output "object_bucket" {
  value = aws_s3_bucket.benchmark_object.bucket
}

output "block_volume_id" {
  value = aws_ebs_volume.benchmark_block.id
}
