terraform {
  source = "../../../aws//cloudtrail"
}

dependencies {
  paths = ["../satellite_bucket"]
}

dependency "satellite_bucket" {
  config_path  = "../satellite_bucket"
  skip_outputs = true
}

include {
  path = find_in_parent_folders()
  expose = true
}