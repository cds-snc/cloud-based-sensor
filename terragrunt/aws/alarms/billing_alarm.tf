# EstimatedCharges metrics are published every ~6 hours
resource "aws_cloudwatch_metric_alarm" "billing_change_over_threshold" {
  provider = aws.us-east-1

  alarm_name          = "BillingChangeOverThreshold"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  threshold           = var.billing_change_percent_threshold
  alarm_description   = "Estimated billing change greater than threshold in 6 hour period"
  alarm_actions       = [aws_sns_topic.cloudwatch_alarm_us_east.arn]
  ok_actions          = [aws_sns_topic.cloudwatch_alarm_us_east.arn]

  metric_query {
    id    = "current"
    label = "Current charges"

    metric {
      metric_name = "EstimatedCharges"
      namespace   = "AWS/Billing"
      period      = "21600"
      stat        = "Maximum"
      dimensions = {
        Currency = "USD"
      }
    }
  }

  metric_query {
    id         = "delta"
    expression = "RATE(current) * PERIOD(current)"
    label      = "Delta"
  }

  metric_query {
    id         = "previous"
    expression = "current - delta"
    label      = "Previous charges"
  }

  metric_query {
    id          = "percent_change"
    expression  = "ABS(100 * delta/previous)"
    label       = "Percent change"
    return_data = "true"
  }
}
