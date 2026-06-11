###############################################################################
# Dedicated security group for the RDS instance.
#
# Ingress on the DB port is allowed ONLY from explicitly provided source
# security groups and/or CIDR blocks. The default is deny-all (no rules),
# and 0.0.0.0/0 is rejected at variable validation.
###############################################################################

resource "aws_security_group" "this" {
  name        = "${var.identifier}-rds-sg"
  description = "Security group for the ${var.identifier} RDS instance"
  vpc_id      = var.vpc_id

  tags = merge(local.common_tags, { Name = "${var.identifier}-rds-sg" })
}

# Ingress from allowed source security groups (e.g. EKS node SG).
resource "aws_security_group_rule" "ingress_from_sg" {
  for_each = toset(var.allowed_security_group_ids)

  type                     = "ingress"
  description              = "DB access from ${each.value}"
  security_group_id        = aws_security_group.this.id
  source_security_group_id = each.value
  from_port                = var.port
  to_port                  = var.port
  protocol                 = "tcp"
}

# Ingress from allowed CIDR blocks (scoped networks only).
resource "aws_security_group_rule" "ingress_from_cidr" {
  count = length(var.allowed_cidr_blocks) > 0 ? 1 : 0

  type              = "ingress"
  description       = "DB access from allowed CIDR blocks"
  security_group_id = aws_security_group.this.id
  cidr_blocks       = var.allowed_cidr_blocks
  from_port         = var.port
  to_port           = var.port
  protocol          = "tcp"
}

# Egress is unrestricted; RDS itself initiates few outbound connections but this
# keeps replication / maintenance traffic unblocked.
resource "aws_security_group_rule" "egress" {
  type              = "egress"
  description       = "Allow all egress"
  security_group_id = aws_security_group.this.id
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
}
