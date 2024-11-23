# CloudWatch Log Group for Lambda with shorter retention
resource "aws_cloudwatch_log_group" "backup_lambda" {
  name              = "/aws/lambda/${var.project_name}-backup"
  retention_in_days = 3

  tags = {
    Environment = var.environment
    Project     = var.project_name
  }
}

# CloudWatch Alarms for Lambda errors
resource "aws_cloudwatch_metric_alarm" "backup_lambda_errors" {
  alarm_name          = "${var.project_name}-backup-errors"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name        = "Errors"
  namespace          = "AWS/Lambda"
  period             = "3600"
  statistic          = "Sum"
  threshold          = "0"
  alarm_description  = "Monitors backup function errors"
  
  dimensions = {
    FunctionName = aws_lambda_function.personal_website_backup.function_name
  }

  alarm_actions = [aws_sns_topic.backup_alerts.arn]
}

# CloudWatch Alarm for S3 bucket size
resource "aws_cloudwatch_metric_alarm" "backup_bucket_size" {
  provider = aws.backup_region
  
  alarm_name          = "${var.project_name}-backup-bucket-size"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name        = "BucketSizeBytes"
  namespace          = "AWS/S3"
  period             = "86400"  # 24 hours
  statistic          = "Average"
  threshold          = var.backup_bucket_size_threshold
  alarm_description  = "This metric monitors backup S3 bucket size"
  
  dimensions = {
    BucketName = aws_s3_bucket.personal_website_backup.id
    StorageType = "StandardStorage"
  }

  alarm_actions = [aws_sns_topic.backup_alerts.arn]
}

# SNS Topic for alerts
resource "aws_sns_topic" "backup_alerts" {
  name = "${var.project_name}-backup-alerts"
}

# SNS Topic subscription
resource "aws_sns_topic_subscription" "backup_alerts_email" {
  topic_arn = aws_sns_topic.backup_alerts.arn
  protocol  = "email"
  endpoint  = var.alert_email
}

# CloudWatch Dashboard
resource "aws_cloudwatch_dashboard" "backup_dashboard" {
  dashboard_name = "${var.project_name}-backup"

  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "metric"
        x      = 0
        y      = 0
        width  = 24
        height = 6

        properties = {
          metrics = [
            ["AWS/Lambda", "Errors", "FunctionName", aws_lambda_function.personal_website_backup.function_name],
            [".", "Success", ".", "."]
          ]
          period = 3600
          stat   = "Sum"
          region = var.aws_region
          title  = "Backup Status (Hourly)"
        }
      }
    ]
  })
}

# 添加成本预算告警
resource "aws_budgets_budget" "backup_cost" {
  name              = "${var.project_name}-backup-budget"
  budget_type       = "COST"
  limit_amount      = "10"
  limit_unit        = "USD"
  time_period_start = "2024-01-01_00:00"
  time_unit         = "MONTHLY"

  notification {
    comparison_operator = "GREATER_THAN"
    threshold          = 80
    threshold_type     = "PERCENTAGE"
    notification_type  = "ACTUAL"
    subscriber_email_addresses = [var.alert_email]
  }
} 