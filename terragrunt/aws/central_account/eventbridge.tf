# Required for CBS v2.3
resource "aws_cloudwatch_event_rule" "cbs" {
  name        = "cbs"
  description = "Sends replication events from ${var.log_archive_bucket_name} to CBS."

  event_pattern = jsonencode({
    source = ["aws.s3"]
    detail = {
      "userIdentity" : {
        "principalId" : [{ "suffix" : ":s3-replication" }]
      }
      "eventName" : ["PutObject"]
      "requestParameters" : {
        "bucketName" : ["${var.log_archive_bucket_name}"]
      }
      "additionalEventData" : {
        "bytesTransferredIn" : [{ "numeric" : [">", 0] }]
      }
    }
  })
  tags = {
    Owner = "CBS"
  }
}

resource "aws_cloudwatch_event_target" "cross_account" {
  arn      = var.cbs_destination_event_bus_arn
  rule     = aws_cloudwatch_event_rule.cbs.name
  role_arn = aws_iam_role.event_bus_invoke_remote_event_bus.arn
}
