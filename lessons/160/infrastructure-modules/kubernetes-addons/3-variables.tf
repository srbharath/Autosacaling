variable "eks_name" {
  description = "Name of the cluster."
  type        = string
}

variable "enable_cluster_autoscaler" {
  description = "Determines whether to deploy cluster autoscaler"
  type        = bool
  default     = false
}

variable "load_balancer_controller" {
  description = "Determines whether to deploy Load Balancer Controller"
  type        = bool
  default     = false
}

variable "openid_provider_arn" {
  description = "IAM Openid Connect Provider ARN"
  type        = string
}
