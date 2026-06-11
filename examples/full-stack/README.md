# Full-stack example

Wires the three modules into a working environment:

```
module.vpc  -->  module.eks  -->  module.rds
   |                |               ^
   | private        | node SG ------/  (RDS ingress only from EKS nodes)
   | subnets -------/
```

- The VPC tags subnets for the EKS cluster (ELB/ALB auto-discovery).
- EKS runs in the private subnets with a managed node group + cluster-autoscaler IRSA role.
- RDS (PostgreSQL 16) accepts connections **only** from the EKS node security group.

## Prerequisites

- Terraform >= 1.5.0
- AWS credentials configured (profile or OIDC — never hardcode keys)
- Permissions to create VPC / EKS / RDS / IAM resources

## Run

```bash
cp terraform.tfvars.example terraform.tfvars   # edit as needed
terraform init
terraform plan
terraform apply
```

Connect `kubectl` to the cluster:

```bash
$(terraform output -raw kubeconfig_command)
```

Read the generated DB password (if you did not provide one):

```bash
terraform output -raw rds_password
```

## Cleanup

```bash
terraform destroy
```

> The example sets `deletion_protection = false` and `skip_final_snapshot = true`
> so it tears down cleanly. **Flip both for production.**

## Cost note

This provisions an EKS control plane, EC2 nodes, NAT gateway, and an RDS
instance — all billable. Destroy when you are done experimenting.
