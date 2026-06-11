###############################################################################
# Full-stack example: VPC -> EKS -> RDS
#
# The VPC tags its subnets for the named EKS cluster, EKS runs in the private
# subnets, and RDS only accepts connections from the EKS node security group.
###############################################################################

locals {
  cluster_name = "${var.name_prefix}-eks"
}

module "vpc" {
  source = "../../modules/vpc"

  name               = var.name_prefix
  cidr               = var.cidr
  azs                = var.azs
  single_nat_gateway = true
  eks_cluster_name   = local.cluster_name
}

module "eks" {
  source = "../../modules/eks"

  cluster_name       = local.cluster_name
  kubernetes_version = var.kubernetes_version
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
}

module "rds" {
  source = "../../modules/rds"

  identifier     = "${var.name_prefix}-pg"
  vpc_id         = module.vpc.vpc_id
  subnet_ids     = module.vpc.private_subnet_ids
  engine_version = "16.3"
  instance_class = "db.t3.micro"

  db_name  = var.db_name
  username = var.db_username
  password = var.db_password

  # Only the EKS worker nodes may reach the database.
  allowed_security_group_ids = [module.eks.node_security_group_id]

  # Example defaults: keep it cheap and disposable. Flip these for production.
  multi_az            = false
  deletion_protection = false
  skip_final_snapshot = true
}
