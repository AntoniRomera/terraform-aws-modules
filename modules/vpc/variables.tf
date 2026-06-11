variable "name" {
  description = "Name prefix applied to the VPC and all networking resources."
  type        = string

  validation {
    condition     = length(var.name) > 0 && length(var.name) <= 100
    error_message = "name must be between 1 and 100 characters."
  }
}

variable "cidr" {
  description = "IPv4 CIDR block for the VPC (RFC1918 documentation ranges recommended)."
  type        = string
  default     = "10.0.0.0/16"

  validation {
    # can(cidrhost(...)) fails for malformed CIDRs, giving us cheap validation.
    condition     = can(cidrhost(var.cidr, 0))
    error_message = "cidr must be a valid IPv4 CIDR block, e.g. 10.0.0.0/16."
  }
}

variable "azs" {
  description = "Availability Zones to spread subnets across. At least two for HA."
  type        = list(string)

  validation {
    condition     = length(var.azs) >= 2
    error_message = "Provide at least two availability zones for high availability."
  }
}

variable "single_nat_gateway" {
  description = "When true, route all private subnets through one shared NAT gateway (cheaper). When false, one NAT gateway per AZ (highly available)."
  type        = bool
  default     = true
}

variable "enable_dns_hostnames" {
  description = "Enable DNS hostnames in the VPC (required for many AWS services, including EKS)."
  type        = bool
  default     = true
}

variable "eks_cluster_name" {
  description = "Optional EKS cluster name. When set, subnets are tagged for ELB/ALB auto-discovery and cluster ownership."
  type        = string
  default     = null
}

variable "tags" {
  description = "Tags applied to all resources created by this module."
  type        = map(string)
  default     = {}
}
