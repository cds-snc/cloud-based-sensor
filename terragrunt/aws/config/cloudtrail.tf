resource "aws_config_config_rule" "cbs_cloudtrail_enabled" {
  name             = "cbs_cloudtrail_enabled"
  description      = "A Config rule that checks that CloudTrail is enabled and logging to a given bucket."
  input_parameters = jsonencode({ "s3BucketName" = var.satellite_bucket_name })

  source {
    owner             = "AWS"
    source_identifier = "CLOUD_TRAIL_ENABLED"
  }

  scope {
    compliance_resource_types = [
      "AWS::CloudTrail::Trail"
    ]
  }
}
