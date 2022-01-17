resource "aws_config_config_rule" "cbs_s3_bucket_logging_enabled" {
  name             = "cbs_s3_bucket_logging_enabled"
  description      = "A Config rule that checks whether logging to the cbs satellite is enabled for your S3 buckets."
  input_parameters = jsonencode({ "targetBucket" = var.bucket_name })

  source {
    owner             = "AWS"
    source_identifier = "S3_BUCKET_LOGGING_ENABLED"
  }
  scope {
    compliance_resource_types = ["AWS::S3::Bucket"]
  }
}

resource "aws_config_remediation_configuration" "cbs_s3_bucket_logging_enabled" {
  config_rule_name = aws_config_config_rule.cbs_s3_bucket_logging_enabled.name
  resource_type    = "AWS::S3::Bucket"
  target_type      = "SSM_DOCUMENT"
  target_id        = "AWS-ConfigureS3BucketLogging"
  target_version   = "1"

  parameter {
    name         = "AutomationAssumeRole"
    static_value = aws_iam_role.security_config.arn
  }
  parameter {
    name           = "BucketName"
    resource_value = "RESOURCE_ID"
  }
  parameter {
    name         = "TargetBucket"
    static_value = var.bucket_name
  }
  parameter {
    name         = "GrantedPermission"
    static_value = "FULL_CONTROL"
  }
  parameter {
    name         = "GranteeType"
    static_value = "Group"
  }
  parameter {
    name         = "GranteeUri"
    static_value = "http://acs.amazonaws.com/groups/s3/LogDelivery"
  }
  parameter {
    name         = "SSEAlgorithm"
    static_value = "AES256"
  }

  automatic                  = true
  maximum_automatic_attempts = 10
  retry_attempt_seconds      = 3600

  execution_controls {
    ssm_controls {
      concurrent_execution_rate_percentage = 25
      error_percentage                     = 20
    }
  }
}
