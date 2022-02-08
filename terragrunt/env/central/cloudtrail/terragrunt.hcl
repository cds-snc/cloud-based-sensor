terraform {
  source = "../../../aws//cloudtrail"
}

inputs = {
  cloudtrail_bucket_name = include.inputs.log_archive_bucket_name
}

include {
  path = find_in_parent_folders()
  expose = true
}