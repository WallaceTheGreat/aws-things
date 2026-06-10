# Plan de Reprise d'Activité (PRA) — Projet 7

## 1. Périmètre et objectifs

| Paramètre | Valeur |
|-----------|--------|
| Application | BaaS sécurisée : DynamoDB + S3 + Lambda |
| RPO cible | 1 heure (perte de données max acceptable) |
| RTO cible | 4 heures (durée max avant remise en service) |
| Responsable | DevOps + DBA (équipe projet) |
| Fréquence revue | Semestrielle ou après tout incident |
| Outil de restauration | Terraform + `restore.sh` |

## 2. Scénarios et procédures

| Scénario | RTO | RPO | Procédure |
|----------|-----|-----|-----------|
| Suppression accidentelle S3 | < 30min | < 1h | `s3api list-object-versions` → `copy-object` (restaurer version) |
| Corruption DynamoDB | < 2h | < 1h | Restaurer depuis snapshot AWS Backup → valider intégrité → relancer |
| Clé KMS compromise | < 4h | 0 | Disable key → new key → re-chiffrer → update policies → audit logs |
| Intrusion réseau | < 1h | 0 | Modifier SG → invalider IAM keys → analyser CloudWatch → notifier RSSI |
| Panne totale infra | < 8h | < 1h | `terraform destroy` → `apply` → restaurer backup → update DNS |

## 3. Script de restauration

`restore.sh` automatise 4 scénarios : `s3-restore`, `infra-rebuild`,
`network-lockdown`, `kms-rotation`.

```bash
./restore.sh network-lockdown   # isole le SG en urgence
./restore.sh kms-rotation       # désactive + redéploie la clé KMS
```

## 4. Plan de secours (fallback)

Si `terraform apply` échoue pendant la restauration :
1. Rollback vers le dernier tag stable (`git checkout <tag>`)
2. Restaurer manuellement les ressources critiques via `awslocal`
3. Activer le mode maintenance (page statique S3)

Si LocalStack/région primaire indisponible :
1. Basculer vers région secondaire (`terraform workspace select dr`)
2. Mettre à jour Route 53 vers la région secondaire
3. Notifier via la page de statut

Contact d'urgence : DevOps → DBA → RSSI → Direction

## 5. Planning des tests PRA

| Test | Fréquence | Procédure |
|------|-----------|-----------|
| Restauration S3 | Mensuel | Restaurer un fichier depuis version précédente, valider |
| Rebuild complet infra | Trimestriel | `destroy` + `apply`, mesurer temps vs RTO 4h |
| Simulation intrusion | Semestriel | Simuler IP malveillante, vérifier détection + lockdown |
| Exercice PRA complet | Annuel | Simuler perte totale, chronométrer chaque étape |
