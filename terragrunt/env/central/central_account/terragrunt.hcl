terraform {
  source = "../../../aws//central_account"
}

include {
  path = find_in_parent_folders()
  expose = true
}
