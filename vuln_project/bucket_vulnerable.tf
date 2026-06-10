# !! CE CODE EST VOLONTAIREMENT NON SECURISE — USAGE PEDAGOGIQUE UNIQUEMENT !!

resource "aws_s3_bucket" "vulnerable" {
  bucket = "bucket-vulnerable-demo"
  # OUBLI 1 : pas de tags, pas de description
}

# Necessaire pour qu'une ACL publique soit acceptee (sinon AccessControlListNotSupported)
resource "aws_s3_bucket_ownership_controls" "vulnerable" {
  bucket = aws_s3_bucket.vulnerable.id
  rule { object_ownership = "BucketOwnerPreferred" }
}

# OUBLI 2 : acces public NON bloque
# resource "aws_s3_bucket_public_access_block" ... { MANQUANT }

# OUBLI 3 : ACL publique (tout le monde peut lire)
resource "aws_s3_bucket_acl" "vulnerable_acl" {
  bucket     = aws_s3_bucket.vulnerable.id
  acl        = "public-read" # !! DANGEREUX : tout internet peut lire
  depends_on = [aws_s3_bucket_ownership_controls.vulnerable]
}

# OUBLI 4 : pas de chiffrement
# resource "aws_s3_bucket_server_side_encryption_configuration" ... { MANQUANT }

# OUBLI 5 : pas de versioning (pas de recuperation en cas d'effacement)
# resource "aws_s3_bucket_versioning" ... { MANQUANT }

# OUBLI 6 : politique permissive (tout le monde peut lire et lister)
resource "aws_s3_bucket_policy" "vulnerable_policy" {
  bucket = aws_s3_bucket.vulnerable.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = "*" # !! TOUT LE MONDE
      Action    = ["s3:GetObject", "s3:ListBucket"]
      Resource = [
        "arn:aws:s3:::bucket-vulnerable-demo",
        "arn:aws:s3:::bucket-vulnerable-demo/*"
      ]
    }]
  })
}
