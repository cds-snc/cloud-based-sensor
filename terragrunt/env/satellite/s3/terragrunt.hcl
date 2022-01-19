terraform {
  source = "../../../aws//s3"
}

inputs = {
  bucket_name = "cbs-central-satellite-${get_aws_account_id()}"
  cbs_central_bucket_arn = "arn:aws:s3:::cbs-central-log-archive-339850311124"
}

include {
  path = find_in_parent_folders()
  expose = true
}
