terraform {
  source = "../../aws/cbs_s3_bucket.tf"
}

include {
  path = find_in_parent_folders()
}
