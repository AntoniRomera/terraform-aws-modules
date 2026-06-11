variable "cluster_name" {
  description = "Name of the EKS cluster."
  type        = string

  validation {
    # AWS EKS cluster naming rules: alphanumeric + hyphens, start with a letter/digit.
    condition     = can(regex("^[a-zA-Z0-9][a-zA-Z0-9-]{0,99}$", var.cluster_name))
    error_message = "cluster_name must be 1-100 chars, alphanumeric or hyphens, and start with a letter or digit."
  }
}

variable "kubernetes_version" {
  description = "Kubernetes minor version for the control plane."
  type        = string
  default     = "1.29"

  validation {
    condition     = can(regex("^1\\.(2[4-9]|3[0-9])$", var.kubernetes_version))
    error_message = "kubernetes_version must look like '1.29'."
  }
}

variable "vpc_id" {
  description = "VPC the cluster and nodes run in."
  type        = string
}

variable "subnet_ids" {
  description = "Subnet IDs for the control plane ENIs and node groups (typically private subnets)."
  type        = list(string)

  validation {
    condition     = length(var.subnet_ids) >= 2
    error_message = "EKS requires at least two subnets in different AZs."
  }
}

variable "endpoint_public_access" {
  description = "Whether the cluster API server is reachable from the public internet."
  type        = bool
  default     = true
}

variable "endpoint_private_access" {
  description = "Whether the cluster API server is reachable from within the VPC."
  type        = bool
  default     = true
}

variable "public_access_cidrs" {
  description = "CIDR blocks allowed to reach the public API endpoint. Tighten this in production."
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "node_groups" {
  description = "Map of managed node groups. Key is the node group name."
  type = map(object({
    instance_types = optional(list(string), ["t3.medium"])
    capacity_type  = optional(string, "ON_DEMAND")
    min_size       = optional(number, 1)
    max_size       = optional(number, 3)
    desired_size   = optional(number, 2)
    disk_size      = optional(number, 20)
    labels         = optional(map(string), {})
  }))
  default = {
    default = {
      instance_types = ["t3.medium"]
      min_size       = 1
      max_size       = 3
      desired_size   = 2
    }
  }

  validation {
    condition = alltrue([
      for ng in values(var.node_groups) :
      ng.min_size <= ng.desired_size && ng.desired_size <= ng.max_size
    ])
    error_message = "For every node group, min_size <= desired_size <= max_size must hold."
  }

  validation {
    condition = alltrue([
      for ng in values(var.node_groups) :
      contains(["ON_DEMAND", "SPOT"], ng.capacity_type)
    ])
    error_message = "capacity_type must be either ON_DEMAND or SPOT."
  }
}

variable "enable_cluster_autoscaler_irsa" {
  description = "Create an IRSA role/policy for the Kubernetes Cluster Autoscaler service account."
  type        = bool
  default     = true
}

variable "cluster_autoscaler_service_account" {
  description = "Namespace/name of the cluster-autoscaler service account allowed to assume the IRSA role."
  type        = string
  default     = "kube-system:cluster-autoscaler"
}

variable "tags" {
  description = "Tags applied to all resources created by this module."
  type        = map(string)
  default     = {}
}
