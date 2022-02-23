#
# Attach policy to the Replication role created as part
# of the `bootstrap/satellite_account_iam`.
#

resource "aws_iam_role" "s3_replicate" {
  name               = "CoreReplicateToCBSCentral"
  assume_role_policy = data.aws_iam_policy_document.s3_replicate_assume.json
}

resource "aws_iam_policy" "s3_replicate" {
  name   = "CoreReplicateToCBSCentral"
  path   = "/"
  policy = data.aws_iam_policy_document.s3_replicate.json
}

data "aws_iam_policy_document" "s3_replicate_assume" {
  statement {
    actions = ["sts:AssumeRole"]
    effect  = "Allow"
    principals {
      type        = "Service"
      identifiers = ["s3.amazonaws.com"]
    }
  }
}

resource "aws_iam_role_policy_attachment" "s3_replicate" {
  role       = aws_iam_role.s3_replicate.name
  policy_arn = aws_iam_policy.s3_replicate.arn
}

data "aws_iam_policy_document" "s3_replicate" {
  statement {
    effect = "Allow"
    actions = [
      "s3:GetReplicationConfiguration",
      "s3:ListBucket"
    ]
    resources = [
      var.core_log_archive_bucket_arn,
    ]
  }
  statement {
    effect = "Allow"
    actions = [
      "s3:GetObjectVersion",
      "s3:GetObjectVersionAcl",
      "s3:GetObjectVersionTagging",
      "s3:GetObjectVersionForReplication"
    ]
    resources = [
      "${var.core_log_archive_bucket_arn}/*",
    ]
  }
  statement {
    effect = "Allow"
    actions = [
      "s3:ObjectOwnerOverrideToBucketOwner",
      "s3:ReplicateObject",
      "s3:ReplicateTags",
      "s3:ReplicateDelete"
    ]
    resources = [
      "${local.log_archive_bucket_arn}/*",
      "${local.sentinel_cloudtrail_bucket_arn}/*",
    ]
  }
}
