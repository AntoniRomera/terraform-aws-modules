# `eks` module

Provisions an EKS **control plane**, **managed node groups**, an **IRSA OIDC
provider**, and an optional **Cluster Autoscaler IAM role** wired for IRSA.

## Features

- Control plane with configurable Kubernetes version (default `1.29`).
- Managed node groups driven by a `map(object)` (instance types, capacity type, scaling, labels).
- AL2023 managed nodes; `desired_size` drift is ignored so the autoscaler owns it.
- IRSA via `tls_certificate` → `aws_iam_openid_connect_provider`.
- Cluster-autoscaler IRSA role scoped to `kube-system:cluster-autoscaler` with mutating actions limited to ASGs tagged for this cluster.
- Dedicated node security group exported for downstream ingress (e.g. RDS).

## Usage

```hcl
module "eks" {
  source = "github.com/AntoniRomera/terraform-aws-modules//modules/eks"

  cluster_name       = "demo"
  kubernetes_version = "1.29"
  vpc_id             = module.vpc.vpc_id
  subnet_ids         = module.vpc.private_subnet_ids

  node_groups = {
    default = {
      instance_types = ["t3.medium"]
      capacity_type  = "ON_DEMAND"
      min_size       = 1
      max_size       = 5
      desired_size   = 2
    }
  }

  tags = { Environment = "dev" }
}
```

### Wiring the autoscaler service account

Annotate the `cluster-autoscaler` service account with the role ARN:

```yaml
metadata:
  annotations:
    eks.amazonaws.com/role-arn: <module.eks.cluster_autoscaler_role_arn>
```

## Inputs

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `cluster_name` | `string` | — | Cluster name (regex-validated). |
| `kubernetes_version` | `string` | `"1.29"` | Control plane version. |
| `vpc_id` | `string` | — | VPC for cluster and nodes. |
| `subnet_ids` | `list(string)` | — | Subnets (≥ 2) for control plane + nodes. |
| `endpoint_public_access` | `bool` | `true` | Public API endpoint. |
| `endpoint_private_access` | `bool` | `true` | Private API endpoint. |
| `public_access_cidrs` | `list(string)` | `["0.0.0.0/0"]` | CIDRs allowed to the public endpoint. |
| `node_groups` | `map(object)` | one `default` group | Managed node group definitions. |
| `enable_cluster_autoscaler_irsa` | `bool` | `true` | Create autoscaler IRSA role. |
| `cluster_autoscaler_service_account` | `string` | `"kube-system:cluster-autoscaler"` | SA allowed to assume the role. |
| `tags` | `map(string)` | `{}` | Tags applied to every resource. |

## Outputs

| Name | Description |
|------|-------------|
| `cluster_name` / `cluster_arn` | Cluster identifiers. |
| `cluster_endpoint` | Kubernetes API endpoint. |
| `cluster_certificate_authority_data` | Base64 CA for kubeconfig. |
| `cluster_version` | Running Kubernetes version. |
| `cluster_security_group_id` | EKS-managed cluster SG. |
| `node_security_group_id` | Worker node SG (use as RDS ingress source). |
| `oidc_provider_arn` / `oidc_provider_url` | IRSA OIDC provider. |
| `node_role_arn` | Worker node IAM role ARN. |
| `cluster_autoscaler_role_arn` | Autoscaler IRSA role ARN (or `null`). |
