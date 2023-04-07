variable "subnet_ids" {
  description = "List of subnet IDs. Must be in at least two different availability zones."
  type        = list(string)
}

variable "version" {
  description = "Desired Kubernetes master version."
  type        = string
}

variable "name" {
  description = "Name of the cluster."
  type        = string
}
