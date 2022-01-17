terraform {
  source = "../../../aws//s3"
}

inputs = {
  bucket_name = "cbs-central-satellite-955148791056"
  cbs_central_bucket_arn = "arn:aws:s3:::cbs-central-account-bucket-339850311124"
}

include {
  path = find_in_parent_folders()
}
