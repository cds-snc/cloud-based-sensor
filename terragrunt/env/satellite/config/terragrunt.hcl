terraform {
  source = "../../../aws//config"
}

include {
  path = find_in_parent_folders()
  expose = true
}
