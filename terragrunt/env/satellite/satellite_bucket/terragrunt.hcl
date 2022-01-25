terraform {
  source = "../../../aws//satellite_bucket"
}

inputs = {
  log_archive_kms_key_arn = "arn:aws:kms:ca-central-1:339850311124:key/02bf26d4-b787-485e-91de-c36e5f0fcd91"
}

include {
  path = find_in_parent_folders()
  expose = true
}
