variable "identifier" {
  description = "Unique identifier for the RDS instance."
  type        = string

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{0,62}$", var.identifier))
    error_message = "identifier must start with a lowercase letter and contain only lowercase letters, digits, and hyphens (max 63 chars)."
  }
}

variable "vpc_id" {
  description = "VPC the database and its security group live in."
  type        = string
}

variable "subnet_ids" {
  description = "Subnet IDs for the DB subnet group (private subnets recommended). At least two AZs."
  type        = list(string)

  validation {
    condition     = length(var.subnet_ids) >= 2
    error_message = "RDS subnet groups require at least two subnets in different AZs."
  }
}

variable "engine_version" {
  description = "PostgreSQL engine version."
  type        = string
  default     = "16.3"

  validation {
    condition     = can(regex("^[0-9]+(\\.[0-9]+)?$", var.engine_version))
    error_message = "engine_version must look like '16.3' or '16'."
  }
}

variable "parameter_group_family" {
  description = "DB parameter group family matching the engine version."
  type        = string
  default     = "postgres16"
}

variable "instance_class" {
  description = "Instance class for the RDS instance."
  type        = string
  default     = "db.t3.micro"

  validation {
    condition     = can(regex("^db\\.", var.instance_class))
    error_message = "instance_class must start with 'db.', e.g. db.t3.micro."
  }
}

variable "allocated_storage" {
  description = "Initial storage in GiB."
  type        = number
  default     = 20

  validation {
    condition     = var.allocated_storage >= 20 && var.allocated_storage <= 65536
    error_message = "allocated_storage must be between 20 and 65536 GiB."
  }
}

variable "max_allocated_storage" {
  description = "Upper limit (GiB) for storage autoscaling. Set to 0 to disable autoscaling."
  type        = number
  default     = 100

  validation {
    condition     = var.max_allocated_storage == 0 || var.max_allocated_storage >= 20
    error_message = "max_allocated_storage must be 0 (disabled) or >= 20."
  }
}

variable "db_name" {
  description = "Name of the initial database to create."
  type        = string
  default     = "appdb"

  validation {
    condition     = can(regex("^[a-zA-Z][a-zA-Z0-9_]{0,62}$", var.db_name))
    error_message = "db_name must start with a letter and contain only letters, digits, and underscores."
  }
}

variable "username" {
  description = "Master username for the database."
  type        = string
  default     = "appadmin"
}

variable "password" {
  description = "Master password. Leave null to generate a random password (output as sensitive)."
  type        = string
  default     = null
  sensitive   = true

  validation {
    condition     = var.password == null || length(coalesce(var.password, "________")) >= 8
    error_message = "password must be at least 8 characters when provided."
  }
}

variable "port" {
  description = "Port the database listens on."
  type        = number
  default     = 5432
}

variable "allowed_security_group_ids" {
  description = "Security group IDs allowed to connect on the DB port (e.g. EKS node SG)."
  type        = list(string)
  default     = []
}

variable "allowed_cidr_blocks" {
  description = "CIDR blocks allowed to connect on the DB port. Defaults to none (no 0.0.0.0/0)."
  type        = list(string)
  default     = []

  validation {
    condition     = !contains(var.allowed_cidr_blocks, "0.0.0.0/0")
    error_message = "Refusing 0.0.0.0/0 in allowed_cidr_blocks; scope ingress to specific networks."
  }
}

variable "multi_az" {
  description = "Deploy a standby in another AZ for high availability."
  type        = bool
  default     = false
}

variable "storage_encrypted" {
  description = "Encrypt storage at rest."
  type        = bool
  default     = true
}

variable "deletion_protection" {
  description = "Prevent the instance from being destroyed."
  type        = bool
  default     = true
}

variable "skip_final_snapshot" {
  description = "Skip the final snapshot on deletion. Keep false in production."
  type        = bool
  default     = false
}

variable "backup_retention_period" {
  description = "Days to retain automated backups."
  type        = number
  default     = 7

  validation {
    condition     = var.backup_retention_period >= 0 && var.backup_retention_period <= 35
    error_message = "backup_retention_period must be between 0 and 35 days."
  }
}

variable "tags" {
  description = "Tags applied to all resources created by this module."
  type        = map(string)
  default     = {}
}
