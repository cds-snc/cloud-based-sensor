#
# Config Rule
#
resource "aws_config_config_rule" "cbs_wafv2_logs_rule" {
  name        = "cbs_wafv2_logs_rule"
  description = "Checks that the WAFV2 ACL's are logging to either S3 or Kinesis."

  source {
    owner             = "CUSTOM_LAMBDA"
    source_identifier = aws_lambda_function.cbs_wafv2_logs_rule.arn

    source_detail {
      message_type                = "ScheduledNotification"
      maximum_execution_frequency = var.config_max_execution_frequency
    }
  }

  scope {
    compliance_resource_types = ["AWS::WAFv2::WebACL"]
  }

  depends_on = [
    aws_lambda_permission.cbs_wafv2_logs_rule,
  ]
}

#
# Lambda function used by the ConfigRule
#
data "archive_file" "cbs_wafv2_logs_rule" {
  type        = "zip"
  source_file = "config_rules/wafv2_logs/webacl_logs_rule.py"
  output_path = "/tmp/cbs_wafv2_logs_rule.zip"
}

resource "aws_lambda_function" "cbs_wafv2_logs_rule" {
  filename      = "/tmp/cbs_wafv2_logs_rule.zip"
  function_name = "cbs_wafv2_logs_rule"
  role          = aws_iam_role.cbs_wafv2_logs_rule.arn
  handler       = "webacl_logs_rule.lambda_handler"

  source_code_hash = data.archive_file.cbs_wafv2_logs_rule.output_base64sha256
  runtime          = "python3.9"

  environment {
    variables = {
      FIREHOSE_ARN = aws_kinesis_firehose_delivery_stream.cbs_default_stream.arn
    }
  }

  tracing_config {
    mode = "PassThrough"
  }

  tags = {
    (var.billing_tag_key) = var.billing_tag_value
    Terraform             = true
  }
}

resource "aws_lambda_permission" "cbs_wafv2_logs_rule" {
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.cbs_wafv2_logs_rule.arn
  principal     = "config.amazonaws.com"
  statement_id  = "AllowExecutionFromConfig"
}

resource "aws_cloudwatch_log_group" "cbs_wafv2_logs_rule" {
  name              = "/aws/lambda/${aws_lambda_function.cbs_wafv2_logs_rule.function_name}"
  retention_in_days = 14

  tags = {
    (var.billing_tag_key) = var.billing_tag_value
    Terraform             = true
  }
}

#
# Lambda execution role
#
resource "aws_iam_role" "cbs_wafv2_logs_rule" {
  name               = "cbs_wafv2_logs_rule"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume.json

  tags = {
    (var.billing_tag_key) = var.billing_tag_value
    Terraform             = true
  }
}

resource "aws_iam_role_policy_attachment" "cbs_wafv2_logs_rule_basic_execution" {
  role       = aws_iam_role.cbs_wafv2_logs_rule.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy_attachment" "cbs_wafv2_logs_rule_wafv2_list_web_acls" {
  role       = aws_iam_role.cbs_wafv2_logs_rule.name
  policy_arn = aws_iam_policy.wafv2_list_web_acls.arn
}

resource "aws_iam_policy" "wafv2_list_web_acls" {
  name        = "wafv2_list_web_acls"
  path        = "/"
  description = "IAM policy for listing all WAFv2 ACLs"
  policy      = data.aws_iam_policy_document.wafv2_list_web_acls.json

  tags = {
    (var.billing_tag_key) = var.billing_tag_value
    Terraform             = true
  }
}

data "aws_iam_policy_document" "wafv2_list_web_acls" {
  statement {
    effect = "Allow"
    actions = [
      "wafv2:GetWebACL",
      "wafv2:GetLoggingConfiguration",
      "wafv2:ListWebACLs",
      "wafv2:ListLoggingConfigurations",
      "wafv2:PutLoggingConfiguration",
      "config:PutEvaluations",
      "iam:CreateServiceLinkedRole",
    ]
    resources = ["*"]
  }
}

resource "aws_cloudwatch_log_group" "cbs_default_kinesis_stream" {
  name              = "/aws/kinesisfirehose/cbs_default_kinesis_stream"
  retention_in_days = 14

  tags = {
    CostCentre = var.billing_code
    Terraform  = true
  }
}

resource "aws_kinesis_firehose_delivery_stream" "cbs_default_stream" {
  name        = "aws-waf-logs-${var.account_id}"
  destination = "extended_s3"

  extended_s3_configuration {
    role_arn   = aws_iam_role.waf_log_role.arn
    prefix     = "waf/${var.account_id}/"
    bucket_arn = module.waf_logs.s3_bucket_arn
    cloudwatch_logging_options {
      enabled         = true
      log_group_name  = aws_cloudwatch_log_group.cbs_default_kinesis_stream.name
      log_stream_name = "WAFLogS3Delivery"
    }
  }

  tags = {
    CostCentre = var.billing_code
    Terraform  = true
  }
}

module "waf_logs" {
  source            = "github.com/cds-snc/terraform-modules?ref=v1.0.4//S3"
  bucket_name       = var.aws_waf_log_bucket
  billing_tag_value = var.billing_tag_value

  versioning = {
    enabled = true
  }

  lifecycle_rule = [
    {
      enabled = true
      expiration = {
        days = 14
      }
    }
  ]
}

resource "aws_iam_role" "waf_log_role" {
  name               = "${var.account_id}-logs"
  assume_role_policy = data.aws_iam_policy_document.firehose_assume_role.json

  tags = {
    CostCentre = var.billing_code
    Terraform  = true
  }
}

resource "aws_iam_policy" "write_waf_logs" {
  name        = "${var.account_id}_WriteLogs"
  description = "Allow writing WAF logs to S3 + CloudWatch"
  policy      = data.aws_iam_policy_document.write_waf_logs.json

  tags = {
    CostCentre = var.billing_code
    Terraform  = true
  }
}

resource "aws_iam_role_policy_attachment" "write_waf_logs" {
  role       = aws_iam_role.waf_log_role.name
  policy_arn = aws_iam_policy.write_waf_logs.arn
}

data "aws_iam_policy_document" "firehose_assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["firehose.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

data "aws_iam_policy_document" "write_waf_logs" {
  statement {
    effect = "Allow"

    actions = [
      "s3:ListBucket",
    ]

    resources = [
      module.waf_logs.s3_bucket_arn
    ]
  }

  statement {
    effect = "Allow"

    actions = [
      "s3:GetObject*",
      "s3:PutObject*",
    ]

    resources = [
      "${module.waf_logs.s3_bucket_arn}/waf/*"
    ]
  }
}
