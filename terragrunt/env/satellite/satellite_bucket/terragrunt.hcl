terraform {
  source = "../../../aws//satellite_bucket"
}

inputs = {
  log_archive_kms_key_arn = "someKmsKeyArn"
}

include {
  path = find_in_parent_folders()
  expose = true
}
