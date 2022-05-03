# EstimatedCharges metrics are published every ~6 hours
resource "aws_cloudwatch_metric_alarm" "billing_change_over_threshold" {
  provider = aws.us-east-1

  alarm_name          = "CbsBillingChangeOverThreshold"
  comparison_operator = "GreaterThanUpperThreshold"
  evaluation_periods  = "2"
  threshold_metric_id = "anomaly"
  alarm_description   = "Estimated billing anomaly"
  treat_missing_data  = "notBreaching"
  alarm_actions       = [aws_sns_topic.cloudwatch_alarm_us_east.arn]

  metric_query {
    id          = "anomaly"
    expression  = "ANOMALY_DETECTION_BAND(current, 4)"
    label       = "Billing (Expected)"
    return_data = "true"
  }

  metric_query {
    id          = "current"
    label       = "Current charges"
    return_data = "true"

    metric {
      metric_name = "EstimatedCharges"
      namespace   = "AWS/Billing"
      period      = "43200"
      stat        = "Average"
      dimensions = {
        Currency = "USD"
      }
    }
  }
}
