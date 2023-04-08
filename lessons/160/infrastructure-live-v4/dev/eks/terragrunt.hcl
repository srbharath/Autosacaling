terraform {
  source = "../../../infrastructure-modules/eks"
}

include "root" {
  path = find_in_parent_folders()
}

inputs = {
  eks_version = "1.25"
  eks_name = "dev-demo"
  subnet_ids = dependency.vpc.outputs.private_subnet_ids
}

dependency "vpc" {
  config_path = "../vpc"
}

// dependencies {
//   paths = ["../vpc"]
// }
