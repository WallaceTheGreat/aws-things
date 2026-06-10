# Projet 5 — Vulnérabilité S3 : bucket non sécurisé

Méthode *red team* : déployer un bucket volontairement vulnérable, identifier
les impacts, puis corriger chaque faille. **Ne jamais reproduire en production.**

## Failles intentionnelles du bucket `bucket-vulnerable-demo`

| # | Faille | Impact | Correction Terraform |
|---|--------|--------|----------------------|
| 1 | Public Access Block manquant | Tout internet peut accéder au bucket | `aws_s3_bucket_public_access_block` (4 flags = true) |
| 2 | ACL `public-read` | Fichiers lisibles sans credentials | `acl = private` (défaut) / pas d'ACL |
| 3 | Bucket Policy `Principal: *` | Listage + lecture libres | Restreindre à des ARN spécifiques |
| 4 | Chiffrement absent | Données en clair dans les data centers | `aws_s3_bucket_server_side_encryption_configuration` (AES256) |
| 5 | Versioning absent | Suppression irréversible | `aws_s3_bucket_versioning` enabled |
| 6 | Logging absent | Aucune trace d'accès, intrusion indétectable | `aws_s3_bucket_logging` |

## Simulation d'attaque (LocalStack)

```bash
terraform apply -auto-approve

# Upload de données sensibles
echo "CONFIDENTIEL: mot de passe admin = SuperSecret123" | \
  awslocal s3 cp - s3://bucket-vulnerable-demo/config-secret.txt

# Un attaquant liste le bucket
awslocal s3 ls s3://bucket-vulnerable-demo

# ... et lit n'importe quel fichier
awslocal s3 cp s3://bucket-vulnerable-demo/config-secret.txt -
```

**IMPACT** : violation RGPD + compromission totale du système.

## Version corrigée

`bucket_securise.tf` (`bucket-securise-demo`) applique les 6 corrections :
public access block, ACL privée, policy restreinte, chiffrement AES256,
versioning, logging d'accès.

## Note LocalStack

LocalStack community **n'applique pas** le contrôle d'accès S3 (ACL / bucket
policy ne sont pas évalués pour bloquer une requête). L'exploit ci-dessus est
donc illustratif : sur AWS réel, l'ACL `public-read` + la policy `Principal:*`
exposeraient réellement les fichiers. La valeur pédagogique est dans le code
Terraform (config vulnérable vs corrigée), pas dans l'enforcement runtime.
