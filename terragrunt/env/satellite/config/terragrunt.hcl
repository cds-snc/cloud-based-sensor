terraform {
  source = "../../../aws//config"
}

dependencies {
  paths = ["../cloudtrail"]
}

dependency "cloudtrail" {
  config_path  = "../cloudtrail"
  skip_outputs = true
}

inputs = {
  config_max_execution_frequency = "TwentyFour_Hours"
}

include {
  path = find_in_parent_folders()
  expose = true
}
