# `rds` module

Provisions a **PostgreSQL** `aws_db_instance` with a dedicated subnet group and
a least-privilege security group. Ingress on the DB port is allowed only from
explicitly supplied source security groups / CIDR blocks — never `0.0.0.0/0`.

## Features

- PostgreSQL (default `16.3`, family `postgres16`), `gp3` storage, encrypted at rest by default.
- Storage autoscaling via `max_allocated_storage` (set `0` to disable).
- Password supplied via `var.password` (sensitive) or auto-generated with `random_password`.
- `multi_az`, `deletion_protection` (default on), `skip_final_snapshot` (default off) toggles.
- Default deny-all ingress; pass `allowed_security_group_ids` (e.g. EKS node SG) and/or scoped `allowed_cidr_blocks`.

## Usage

```hcl
module "rds" {
  source = "github.com/AntoniRomera/terraform-aws-modules//modules/rds"

  identifier     = "demo-pg"
  vpc_id         = module.vpc.vpc_id
  subnet_ids     = module.vpc.private_subnet_ids
  engine_version = "16.3"
  instance_class = "db.t3.micro"
  db_name        = "appdb"
  username       = "appadmin"
  # password omitted -> generated; read module.rds.password (sensitive)

  allowed_security_group_ids = [module.eks.node_security_group_id]

  tags = { Environment = "dev" }
}
```

## Inputs (selected)

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `identifier` | `string` | — | Instance identifier (regex-validated). |
| `vpc_id` | `string` | — | VPC for the SG. |
| `subnet_ids` | `list(string)` | — | Private subnets (≥ 2). |
| `engine_version` | `string` | `"16.3"` | PostgreSQL version. |
| `instance_class` | `string` | `"db.t3.micro"` | Must start with `db.`. |
| `allocated_storage` | `number` | `20` | 20–65536 GiB. |
| `max_allocated_storage` | `number` | `100` | `0` disables autoscaling. |
| `db_name` / `username` | `string` | `appdb` / `appadmin` | Initial DB + master user. |
| `password` | `string` (sensitive) | `null` | Provided or auto-generated. |
| `allowed_security_group_ids` | `list(string)` | `[]` | Source SGs allowed on the DB port. |
| `allowed_cidr_blocks` | `list(string)` | `[]` | Scoped CIDRs (rejects `0.0.0.0/0`). |
| `multi_az` / `storage_encrypted` / `deletion_protection` / `skip_final_snapshot` | `bool` | `false` / `true` / `true` / `false` | HA + safety toggles. |

## Outputs

| Name | Description |
|------|-------------|
| `instance_id` / `instance_arn` | Instance identifiers. |
| `endpoint` / `address` / `port` | Connection details. |
| `db_name` / `username` | Database + master user. |
| `password` | Master password (**sensitive**). |
| `security_group_id` | RDS security group ID. |
| `subnet_group_name` | DB subnet group name. |
