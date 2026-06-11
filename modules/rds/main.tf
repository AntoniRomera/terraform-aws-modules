###############################################################################
# RDS module (PostgreSQL)
#
# aws_db_instance + subnet group + (optional) generated password.
# The security group lives in security.tf.
###############################################################################

locals {
  common_tags = merge(var.tags, { "ManagedBy" = "terraform", "Module" = "rds" })

  # Use the caller-supplied password, or fall back to a generated one.
  master_password = var.password != null ? var.password : random_password.master[0].result
}

# Generated only when no password was provided.
resource "random_password" "master" {
  count = var.password == null ? 1 : 0

  length  = 24
  special = true
  # RDS disallows a few characters in master passwords.
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

resource "aws_db_subnet_group" "this" {
  name       = "${var.identifier}-subnet-group"
  subnet_ids = var.subnet_ids

  tags = merge(local.common_tags, { Name = "${var.identifier}-subnet-group" })
}

resource "aws_db_instance" "this" {
  identifier = var.identifier

  engine         = "postgres"
  engine_version = var.engine_version
  instance_class = var.instance_class

  allocated_storage     = var.allocated_storage
  max_allocated_storage = var.max_allocated_storage == 0 ? null : var.max_allocated_storage
  storage_type          = "gp3"
  storage_encrypted     = var.storage_encrypted

  db_name  = var.db_name
  username = var.username
  password = local.master_password
  port     = var.port

  db_subnet_group_name   = aws_db_subnet_group.this.name
  vpc_security_group_ids = [aws_security_group.this.id]

  multi_az                  = var.multi_az
  publicly_accessible       = false
  backup_retention_period   = var.backup_retention_period
  deletion_protection       = var.deletion_protection
  skip_final_snapshot       = var.skip_final_snapshot
  final_snapshot_identifier = var.skip_final_snapshot ? null : "${var.identifier}-final-${formatdate("YYYYMMDDhhmmss", timestamp())}"

  apply_immediately = false

  tags = merge(local.common_tags, { Name = var.identifier })

  lifecycle {
    # final_snapshot_identifier embeds a timestamp; ignore so plans stay clean.
    ignore_changes = [final_snapshot_identifier]
  }
}
