#!/bin/bash
# restore.sh — PRA automatise
# Usage : ./restore.sh [s3-restore|infra-rebuild|network-lockdown|kms-rotation]

SCENARIO=$1
BUCKET_BACKUP="app-backups-securises"
log() { echo "[PRA $(date +%H:%M:%S)] $1"; }

case $SCENARIO in
  "s3-restore")
    log "DEBUT restauration S3"
    awslocal s3api list-object-versions --bucket app-files-securises
    log "Identifiez le VersionId a restaurer, puis :"
    log "awslocal s3api copy-object --copy-source BUCKET/KEY?versionId=ID ..."
    ;;
  "infra-rebuild")
    log "DEBUT reconstruction infrastructure"
    terraform destroy -auto-approve
    terraform apply -auto-approve
    log "Infrastructure reconstruite"
    ;;
  "network-lockdown")
    log "LOCKDOWN reseau - blocage urgence"
    awslocal ec2 revoke-security-group-ingress \
      --group-name app-securisee-sg --protocol tcp \
      --port 0-65535 --cidr 0.0.0.0/0
    log "Reseau isole"
    ;;
  "kms-rotation")
    log "Rotation cle KMS suite compromission"
    awslocal kms disable-key --key-id alias/app-securisee
    terraform apply -target=aws_kms_key.main -auto-approve
    log "Nouvelle cle deployee - re-chiffrement necessaire"
    ;;
  *)
    echo "Usage: $0 [s3-restore|infra-rebuild|network-lockdown|kms-rotation]"
    exit 1
    ;;
esac
