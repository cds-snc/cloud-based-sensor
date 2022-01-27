terraform {
  source = "../../../aws//satellite_bucket"
}

inputs = {
  log_archive_kms_key_arn = "arn:aws:kms:ca-central-1:871282759583:key/c4591f87-9445-4840-acb6-a5569e703c93"
}

include {
  path = find_in_parent_folders()
  expose = true
}
