resource "helm_release" "autoscaler" {
  count = var.enable_cluster_autoscaler ? 1 : 0

  name = "autoscaler"

  repository = "https://kubernetes.github.io/autoscaler"
  chart      = "cluster-autoscaler"
  namespace  = "kube-system"
  version    = "9.28.0"

  set {
    name  = "autoDiscovery.clusterName"
    value = var.eks_name
  }
}
