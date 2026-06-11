###############################################################################
# Minimal example that stores its state in the S3 backend defined in backend.tf.
#
# It provisions just a VPC to keep the demo cheap; the point is to show the
# remote-state wiring, not the resources.
###############################################################################

provider "aws" {
  region = var.region

  default_tags {
    tags = {
      Project   = var.name_prefix
      Example   = "remote-state"
      ManagedBy = "terraform"
    }
  }
}

module "vpc" {
  source = "../../modules/vpc"

  name               = var.name_prefix
  cidr               = var.cidr
  azs                = var.azs
  single_nat_gateway = true
}

output "vpc_id" {
  description = "ID of the VPC whose state is stored remotely."
  value       = module.vpc.vpc_id
}
