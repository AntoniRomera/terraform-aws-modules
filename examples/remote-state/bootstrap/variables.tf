variable "region" {
  description = "AWS region for the state bucket and lock table."
  type        = string
  default     = "eu-west-1"
}

variable "bucket_name" {
  description = "Globally unique name for the S3 state bucket."
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9][a-z0-9.-]{1,61}[a-z0-9]$", var.bucket_name))
    error_message = "bucket_name must be a valid S3 bucket name (lowercase, 3-63 chars)."
  }
}

variable "lock_table_name" {
  description = "Name for the DynamoDB lock table."
  type        = string
  default     = "terraform-state-lock"
}

variable "tags" {
  description = "Tags applied to the bucket and table."
  type        = map(string)
  default = {
    ManagedBy = "terraform"
    Purpose   = "terraform-remote-state"
  }
}
