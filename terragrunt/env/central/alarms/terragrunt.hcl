terraform {
  source = "../../../aws//alarms"
}

include {
  path = find_in_parent_folders()
  expose = true
}
