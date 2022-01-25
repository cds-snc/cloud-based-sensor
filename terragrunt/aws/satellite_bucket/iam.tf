#
# Attach policy to the Replication role created as part
# of the `bootstrap/satellite_account_iam`.
#
data "aws_iam_role" "s3_replicate" {
  name = "CbsSatelliteReplicateToLogArchive"
}

resource "aws_iam_policy" "s3_replicate" {
  name   = "CbsSatelliteReplicateToLogArchive"
  path   = "/"
  policy = data.aws_iam_policy_document.s3_replicate.json
}

resource "aws_iam_role_policy_attachment" "s3_replicate" {
  role       = data.aws_iam_role.s3_replicate.name
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
      module.satellite_bucket.s3_bucket_arn
    ]
  }
  statement {
    effect = "Allow"
    actions = [
      "s3:GetObjectVersion",
      "s3:GetObjectVersionAcl"
    ]
    resources = [
      "${module.satellite_bucket.s3_bucket_arn}/*",
    ]
  }
  statement {
    effect = "Allow"
    actions = [
      "s3:ObjectOwnerOverrideToBucketOwner",
      "s3:ReplicateObject",
      "s3:ReplicateDelete"
    ]
    resources = [
      "${local.log_archive_bucket_arn}/*",
      "${module.satellite_bucket.s3_bucket_arn}/*"
    ]
  }
}
