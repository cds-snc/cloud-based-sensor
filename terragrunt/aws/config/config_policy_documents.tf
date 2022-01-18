// Allow IAM policy to assume the role for AWS Config
data "aws_iam_policy_document" "aws_config_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["config.amazonaws.com"]
    }

    effect = "Allow"
  }
}

data "aws_iam_policy_document" "aws_config_policy" {
  statement {

    effect = "Allow"
    actions = [
      "s3:GetReplicationConfiguration",
      "s3:PutBucketLogging",
    ]
    resources = ["arn:aws:s3:::*"]
  }

}
