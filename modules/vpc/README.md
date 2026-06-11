# `vpc` module

Creates a VPC with one **public** and one **private** subnet per Availability
Zone, an Internet Gateway, NAT gateway(s), and the matching route tables.
Subnet CIDRs are derived from the parent CIDR with `cidrsubnet()` — you never
hardcode subnet ranges.

## Features

- One public + one private subnet per AZ (min 2 AZs).
- Shared single NAT gateway (default, cheaper) or one NAT per AZ (`single_nat_gateway = false`, highly available).
- Public route table → IGW, per-AZ private route tables → NAT.
- Optional EKS subnet tagging (`kubernetes.io/role/elb`, `internal-elb`, cluster ownership) for ELB/ALB auto-discovery.

## Usage

```hcl
module "vpc" {
  source = "github.com/AntoniRomera/terraform-aws-modules//modules/vpc"

  name               = "demo"
  cidr               = "10.0.0.0/16"
  azs                = ["eu-west-1a", "eu-west-1b", "eu-west-1c"]
  single_nat_gateway = true
  eks_cluster_name   = "demo" # optional, enables EKS subnet tags

  tags = {
    Environment = "dev"
    Project     = "terraform-aws-modules"
  }
}
```

## Inputs

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `name` | `string` | — | Name prefix for all resources. |
| `cidr` | `string` | `"10.0.0.0/16"` | VPC IPv4 CIDR (validated via `cidrhost`). |
| `azs` | `list(string)` | — | AZs to spread subnets across (≥ 2). |
| `single_nat_gateway` | `bool` | `true` | One shared NAT vs one NAT per AZ. |
| `enable_dns_hostnames` | `bool` | `true` | Enable DNS hostnames (required by EKS). |
| `eks_cluster_name` | `string` | `null` | When set, tags subnets for the named EKS cluster. |
| `tags` | `map(string)` | `{}` | Tags applied to every resource. |

## Outputs

| Name | Description |
|------|-------------|
| `vpc_id` | VPC ID. |
| `vpc_cidr` | VPC CIDR block. |
| `public_subnet_ids` / `private_subnet_ids` | Subnet IDs per tier. |
| `public_subnet_cidrs` / `private_subnet_cidrs` | Subnet CIDRs per tier. |
| `nat_gateway_ids` | NAT gateway IDs. |
| `internet_gateway_id` | IGW ID. |
| `public_route_table_id` / `private_route_table_ids` | Route table IDs. |
| `azs` | AZs used. |
