terraform {
  source = "../../../infrastructure-modules/vpc"
}

include "root" {
  path = find_in_parent_folders()
}

inputs = {
  instance_count = 10
  instance_type  = "m4.large"
}
