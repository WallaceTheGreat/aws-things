# PILIER 5 — Backup automatique et PRA

# Bucket backup chiffre avec versioning et lifecycle (free tier LocalStack)
resource "aws_s3_bucket" "backup" {
  bucket = "app-backups-securises"
}

resource "aws_s3_bucket_versioning" "backup" {
  bucket = aws_s3_bucket.backup.id
  versioning_configuration { status = "Enabled" }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "backup" {
  bucket = aws_s3_bucket.backup.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = aws_kms_key.main.arn
    }
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "backup" {
  bucket = aws_s3_bucket.backup.id
  rule {
    id     = "backup-lifecycle"
    status = "Enabled"
    filter {}
    transition {
      days          = 30
      storage_class = "STANDARD_IA"
    }
    transition {
      days          = 90
      storage_class = "GLACIER"
    }
    expiration { days = 365 }
  }
}

# Vault AWS Backup centralise + plan quotidien.
# NOTE: le service "backup" est une fonctionnalite LocalStack Pro.
# Sur l'edition community ces 2 ressources renvoient 501. Decommenter
# sur AWS reel / LocalStack Pro.
# resource "aws_backup_vault" "main" {
#   name        = "app-backup-vault"
#   kms_key_arn = aws_kms_key.main.arn
# }
#
# resource "aws_backup_plan" "daily" {
#   name = "DailyBackupPlan"
#   rule {
#     rule_name         = "backup-quotidien"
#     target_vault_name = aws_backup_vault.main.name
#     schedule          = "cron(0 2 * * ? *)" # 2h chaque nuit
#     lifecycle { delete_after = 30 }
#   }
# }
