terraform {
  source = "../../../aws//cloudtrail"
}

include {
  path = find_in_parent_folders()
  expose = true
}