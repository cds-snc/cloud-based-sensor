data "aws_iam_role" "landing_zone_config_recorder_role" {
  name = "AWS-Landing-Zone-ConfigRecorderRole"
}

resource "aws_iam_role" "security_config" {
  count              = var.config_rules_ff ? 1 : 0
  name               = "CbsConfigPolicy"
  assume_role_policy = data.aws_iam_policy_document.aws_config_assume_role_policy[0].json
}

resource "aws_iam_policy_attachment" "managed_policy" {
  count = var.config_rules_ff ? 1 : 0
  name  = "CbsConfigManagedPolicy"
  roles = [
    aws_iam_role.security_config[0].name,
    aws_iam_role.cbs_s3_satellite_bucket_rule[0].name,
    data.aws_iam_role.landing_zone_config_recorder_role.name,
  ]
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWS_ConfigRole"
}

resource "aws_iam_policy" "aws_config_policy" {
  count  = var.config_rules_ff ? 1 : 0
  name   = "CbsConfigPolicy"
  policy = data.aws_iam_policy_document.aws_config_policy[0].json
}

resource "aws_iam_policy_attachment" "aws-aws_config_policy-policy" {
  count      = var.config_rules_ff ? 1 : 0
  name       = "CbsConfigPolicy"
  roles      = ["${aws_iam_role.security_config[0].name}"]
  policy_arn = aws_iam_policy.aws_config_policy[0].arn
}

data "aws_iam_policy_document" "lambda_assume" {
  count = var.config_rules_ff ? 1 : 0
  statement {
    actions = ["sts:AssumeRole"]
    effect  = "Allow"

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}
