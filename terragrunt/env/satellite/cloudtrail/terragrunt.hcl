terraform {
  source = "../../../aws//cloudtrail"
}

inputs = {
  cloudtrail_bucket_name = include.inputs.satellite_bucket_name
}

include {
  path = find_in_parent_folders()
  expose = true
}