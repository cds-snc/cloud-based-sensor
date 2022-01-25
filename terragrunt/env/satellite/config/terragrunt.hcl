terraform {
  source = "../../../aws//config"
}

inputs = {
  config_max_execution_frequency = "TwentyFour_Hours"
}

include {
  path = find_in_parent_folders()
  expose = true
}
