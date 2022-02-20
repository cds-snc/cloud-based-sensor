terraform {
  source = "../../../aws//alarms"
}

inputs = {
  billing_change_percent_threshold = "10"
}

include {
  path = find_in_parent_folders()
  expose = true
}
