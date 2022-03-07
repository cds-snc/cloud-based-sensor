terraform {
  source = "../../../aws//alarms"
}

inputs = {
}

include {
  path = find_in_parent_folders()
  expose = true
}
