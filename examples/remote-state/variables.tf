variable "region" {
  description = "AWS region to deploy into."
  type        = string
  default     = "eu-west-1"
}

variable "name_prefix" {
  description = "Prefix applied to resource names."
  type        = string
  default     = "remote-state-demo"
}

variable "cidr" {
  description = "VPC CIDR block."
  type        = string
  default     = "10.20.0.0/16"
}

variable "azs" {
  description = "Availability Zones to use."
  type        = list(string)
  default     = ["eu-west-1a", "eu-west-1b"]
}
