terraform {
  source = "../../../aws//central_account"
}

inputs = {
  bucket_name = "cbs-central-satellite-${get_aws_account_id()}"
  cbs_central_bucket_arn = "arn:aws:s3:::cbs-central-log-archive-${get_aws_account_id()}"
  config_max_execution_frequency = "TwentyFour_Hours"
  billing_code = "cbs-central"
}

include {
  path = find_in_parent_folders()
  expose = true
}
