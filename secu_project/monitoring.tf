# PILIER 4 — Monitoring, Logs et Dashboard

resource "aws_cloudwatch_log_group" "app" {
  name              = "/app/production"
  retention_in_days = 30
  kms_key_id        = aws_kms_key.main.arn
}

resource "aws_cloudwatch_log_group" "security" {
  name              = "/app/security"
  retention_in_days = 90 # audit longue duree
  kms_key_id        = aws_kms_key.main.arn
}

resource "aws_sns_topic" "alerts" {
  name              = "app-alerts"
  kms_master_key_id = aws_kms_key.main.id
}

# Alarme : erreurs application
resource "aws_cloudwatch_metric_alarm" "errors" {
  alarm_name          = "app-errors-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "ErrorCount"
  namespace           = "App/Lambda"
  period              = 60
  statistic           = "Sum"
  threshold           = 10
  alarm_actions       = [aws_sns_topic.alerts.arn]
}

# Alarme : activite IAM suspecte
resource "aws_cloudwatch_metric_alarm" "iam_denied" {
  alarm_name          = "iam-access-denied"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "AccessDeniedCount"
  namespace           = "CloudTrailMetrics"
  period              = 300
  statistic           = "Sum"
  threshold           = 5
  alarm_actions       = [aws_sns_topic.alerts.arn]
}

# Dashboard centralise
resource "aws_cloudwatch_dashboard" "app" {
  dashboard_name = "App-Security-Dashboard"
  dashboard_body = jsonencode({
    widgets = [
      { type = "metric", properties = { title = "Erreurs Lambda",
      metrics = [["App/Lambda", "ErrorCount"]], period = 60 } },
      { type = "metric", properties = { title = "Acces refuses IAM",
      metrics = [["CloudTrailMetrics", "AccessDeniedCount"]], period = 300 } },
      { type = "log", properties = { title = "Logs securite",
        query          = "fields @timestamp, @message | sort desc | limit 20",
      logGroupNames = ["/app/security"] } }
    ]
  })
}
