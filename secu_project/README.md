# Projet 7 — Application sécurisée + PRA (tout en un)

Réutilise le BaaS du projet 1 et applique 5 piliers de sécurité + un Plan de
Reprise d'Activité.

## Piliers (fichiers Terraform)

| Pilier | Fichier | Contenu |
|--------|---------|---------|
| 1 — IAM | `iam.tf` | Clé KMS (rotation activée), rôle backend moindre privilège + Deny admin |
| 2 — Chiffrement | `encryption.tf` | S3 chiffré KMS, public access block, policy HTTPS-only |
| 3 — Réseau | `network.tf` | VPC, subnet privé, security group (443 entrant / interne sortant) |
| 4 — Monitoring | `monitoring.tf` | Log groups (KMS), SNS alerts, alarmes, dashboard |
| 5 — Backup/PRA | `backup.tf` + `restore.sh` + `PRA.md` | Bucket backup chiffré/versionné/lifecycle + plan de reprise |

## Déploiement

```bash
terraform init && terraform apply -auto-approve
```

## Vérifié sur LocalStack 3.8.1 (21 ressources)

- KMS : `enable_key_rotation = true` → rotation **True**
- S3 `app-files-securises` : SSE **aws:kms**, policy **Deny si SecureTransport=false**
- Log groups `/app/production` (30j) + `/app/security` (90j)
- SNS topic `app-alerts`, 2 alarmes, dashboard

## Limitations LocalStack community

- **`aws_backup_vault` / `aws_backup_plan`** : service `backup` = Pro. Commentés
  dans `backup.tf` ; décommenter sur AWS réel / Pro.
- **S3 lifecycle** : la config est bien appliquée mais le waiter du provider AWS
  ne se stabilise pas en community (timeout) → ressource importée dans le state
  (`terraform import`).
- **`ListDashboards`** : l'API community renvoie 500, mais le dashboard est créé
  (présent dans le state Terraform).
- **IAM** : les `Deny` ne sont pas évalués au runtime (validation par lecture du
  document de policy, comme au projet 3).
