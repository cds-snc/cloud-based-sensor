## Enable s3 access logging to satelitte bucket
---

Remediated using AWS managed `AWS-ConfigureS3BucketLogging` remediation using Terraform.

### AWS permissions required
```json
{
  "Effect": "Allow",
  "Action": "s3:PutBucketLogging",
  "Resource": "arn:aws:s3:::*"
}
```

---

### Placeholder reference until implemented in Terraform
***Delete TF code below and mention this is done in TF***
```HCL
resource "aws_config_remediation_configuration" "this" {
  config_rule_name = aws_config_config_rule.this.name
  resource_type    = "AWS::S3::Bucket"
  target_type      = "SSM_DOCUMENT"
  target_id        = "AWS-ConfigureS3BucketLogging"
  target_version   = "1"

  parameter {
    name         = "AutomationAssumeRole"
    static_value = "arn:aws:iam::${var.account_id}:role/security_config"
  }
  parameter {
    name           = "BucketName"
    resource_value = "RESOURCE_ID"
  }
  parameter {
    name           = "TargetBucket"
    static_value   = "log-archive-satellite-${var.account_id}"
  }
  parameter {
    name           = "GrantedPermission"
    static_value   = "FULL_CONTROL"
  }
  parameter {
    name           = "GranteeType"
    static_value   = "Group"
  }
  parameter {
    name           = "GranteeUri"
    static_value   = "http://acs.amazonaws.com/groups/s3/LogDelivery"
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

```