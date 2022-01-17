terraform {
  source = "../../../aws//config"
}

inputs = {
  bucket_name = "cbs-central-satellite-${include.inputs.account_id}"
  cbs_central_bucket_arn = "arn:aws:s3:::cbs-central-account-bucket-339850311124"
  config_max_execution_frequency = "TwentyFour_Hours"
}

include {
  path = find_in_parent_folders()
  expose = true
}
