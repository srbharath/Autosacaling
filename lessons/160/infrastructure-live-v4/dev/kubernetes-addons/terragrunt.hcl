terraform {
  source = "../../../infrastructure-modules/kubernetes-addons"
}

include "root" {
  path = find_in_parent_folders()
}

inputs = {
  eks_name  = dependency.eks.outputs.eks_name
  enable_cluster_autoscaler = true
}

dependency "eks" {
  config_path = "../eks"

  mock_outputs = {
    eks_name = ["demo"]
  }
}
