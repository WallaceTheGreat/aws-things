# 1. Groupe "developpeurs" (reutilisable pour plusieurs collegues)
resource "aws_iam_group" "developers" {
  name = "developers"
}

# 2. Policy : droit EC2 limite (pas de suppression VPC, pas d'IAM)
resource "aws_iam_policy" "dev_ec2_policy" {
  name        = "DevEC2LimitedPolicy"
  description = "Collegue peut deployer EC2 mais pas modifier IAM ni S3"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowEC2Deploy"
        Effect = "Allow"
        Action = [
          "ec2:RunInstances",
          "ec2:DescribeInstances",
          "ec2:StartInstances",
          "ec2:StopInstances",
          "ec2:DescribeSecurityGroups",
          "ec2:CreateSecurityGroup",
          "ec2:AuthorizeSecurityGroupIngress"
        ]
        Resource = "*"
      },
      {
        Sid      = "AllowReadOwnLogs"
        Effect   = "Allow"
        Action   = ["logs:GetLogEvents", "logs:DescribeLogGroups"]
        Resource = "arn:aws:logs:*:*:log-group:/collegue/*"
      },
      {
        Sid      = "DenyIAMAndS3"
        Effect   = "Deny"
        Action   = ["iam:*", "s3:*", "kms:*"]
        Resource = "*"
      }
    ]
  })
}

# 3. Attacher la policy au groupe
resource "aws_iam_group_policy_attachment" "dev_policy" {
  group      = aws_iam_group.developers.name
  policy_arn = aws_iam_policy.dev_ec2_policy.arn
}

# 4. Compte utilisateur pour le collegue
resource "aws_iam_user" "collegue" {
  name = "collegue-dupont"
  tags = { Role = "developer", Projet = "cours-terraform" }
}

# 5. Ajouter le collegue dans le groupe
resource "aws_iam_user_group_membership" "collegue_dev" {
  user   = aws_iam_user.collegue.name
  groups = [aws_iam_group.developers.name]
}

# 6. Cles d'acces programmatiques pour le collegue
resource "aws_iam_access_key" "collegue_key" {
  user = aws_iam_user.collegue.name
}

# 7. Outputs : credentials a transmettre de facon securisee
output "collegue_access_key" {
  value     = aws_iam_access_key.collegue_key.id
  sensitive = false
}

output "collegue_secret_key" {
  value     = aws_iam_access_key.collegue_key.secret
  sensitive = true
}
