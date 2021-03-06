data "aws_iam_role" "landing_zone_config_recorder_role" {
  name = "AWS-Landing-Zone-ConfigRecorderRole"
}

resource "aws_iam_role" "security_config" {
  name               = "CbsConfigPolicy"
  assume_role_policy = data.aws_iam_policy_document.aws_config_assume_role_policy.json
}

resource "aws_iam_policy_attachment" "managed_policy" {
  name = "CbsConfigManagedPolicy"
  roles = [
    aws_iam_role.security_config.name,
    aws_iam_role.cbs_s3_satellite_bucket_rule.name,
    data.aws_iam_role.landing_zone_config_recorder_role.name,
  ]
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWS_ConfigRole"
}

resource "aws_iam_policy" "aws_config_policy" {
  name   = "CbsConfigPolicy"
  policy = data.aws_iam_policy_document.aws_config_policy.json
}

resource "aws_iam_policy_attachment" "aws-aws_config_policy-policy" {
  name       = "CbsConfigPolicy"
  roles      = ["${aws_iam_role.security_config.name}"]
  policy_arn = aws_iam_policy.aws_config_policy.arn
}

data "aws_iam_policy_document" "lambda_assume" {
  statement {
    actions = ["sts:AssumeRole"]
    effect  = "Allow"

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}
