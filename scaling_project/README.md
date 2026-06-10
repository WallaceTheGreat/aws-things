# Projet 6 — Scalabilité : Auto Scaling sous charge

Auto Scaling Group + Launch Template + alarmes CloudWatch pour scaler les
instances selon la charge CPU.

## Ressources

| Fichier | Contenu |
|---------|---------|
| `network.tf` | VPC, subnet public, security group `app-sg` |
| `scaling.tf` | Launch Template, ASG (min 1 / max 5), policies scale-out/in, alarmes CPU |

## Logique de scaling

```
CPU > 70% (2 min) --> alarme cpu-high-70 --> scale-out (+2 instances, cooldown 120s)
CPU < 20% (5 min) --> alarme cpu-low-20  --> scale-in  (-1 instance,  cooldown 300s)
```

## Déploiement / test (sur AWS réel ou LocalStack Pro)

```bash
terraform apply -auto-approve
awslocal autoscaling describe-auto-scaling-groups --auto-scaling-group-names app-asg
# Simuler une charge CPU
awslocal cloudwatch put-metric-data --namespace "AWS/EC2" \
  --metric-name CPUUtilization \
  --dimensions "Name=AutoScalingGroupName,Value=app-asg" --value 85 --unit Percent
awslocal autoscaling describe-scaling-activities --auto-scaling-group-name app-asg
```

## ⚠️ Limitation LocalStack community

Le service **`autoscaling` est une fonctionnalité Pro** de LocalStack. Sur
l'édition community, `CreateAutoScalingGroup` renvoie :

```
501 InternalFailure: API for service 'autoscaling' not yet implemented or pro feature
```

Ce qui se déploie en community : **VPC, subnet, security group, launch
template** (vérifié — `lt-...`, `sg-...`, `subnet-...`). L'ASG, les scaling
policies et les alarmes (qui référencent les ARN des policies) nécessitent
LocalStack Pro ou un vrai compte AWS. Le code Terraform est correct et
complet pour ces environnements.
