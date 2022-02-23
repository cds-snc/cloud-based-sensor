terraform {
  source = "../../../aws//core_account"
}

include {
  path = find_in_parent_folders()
  expose = true
}