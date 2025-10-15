# =============================================================================
# Eventim DevOps Challenge - Terraform + AWS CDK + Kubernetes (Rancher)
# =============================================================================


# =============================================================================
# Providers Configuration
# =============================================================================

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = var.common_tags
  }
}

provider "helm" {
  kubernetes {
    host                   = module.eks.cluster_endpoint
    cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
    token                  = data.aws_eks_cluster_auth.cluster.token
  }
}

provider "kubernetes" {
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
  token                  = data.aws_eks_cluster_auth.cluster.token
}

# =============================================================================
# Data Sources
# =============================================================================

data "aws_eks_cluster_auth" "cluster" {
  name = module.eks.cluster_name
}

data "aws_availability_zones" "available" {
  state = "available"
}

# Use only 2 availability zones to reduce costs
locals {
  availability_zones = slice(data.aws_availability_zones.available.names, 0, 2)
}

# =============================================================================
# VPC Module
# =============================================================================

module "vpc" {
  source = "./modules/vpc"

  project_name       = var.project_name
  environment        = var.environment
  vpc_cidr           = var.vpc_cidr
  availability_zones = local.availability_zones
  common_tags        = var.common_tags
}

# =============================================================================
# Security Groups Module
# =============================================================================

module "security_groups" {
  source = "./modules/security-groups"

  project_name = var.project_name
  environment  = var.environment
  vpc_id       = module.vpc.vpc_id
  common_tags  = var.common_tags
}

# =============================================================================
# EKS Cluster Module
# =============================================================================

module "eks" {
  source = "./modules/eks"

  project_name             = var.project_name
  environment              = var.environment
  vpc_id                   = module.vpc.vpc_id
  private_subnet_ids       = module.vpc.private_subnet_ids
  public_subnet_ids        = module.vpc.public_subnet_ids
  security_group_id        = module.security_groups.eks_security_group_id
  cluster_version          = var.cluster_version
  node_group_instance_types = var.node_group_instance_types
  node_group_desired_size  = var.node_group_desired_size
  node_group_max_size      = var.node_group_max_size
  node_group_min_size      = var.node_group_min_size
  common_tags              = var.common_tags
}

# =============================================================================
# Rancher Module
# =============================================================================

module "rancher" {
  source = "./modules/rancher"

  project_name     = var.project_name
  environment      = var.environment
  cluster_name     = module.eks.cluster_name
  cluster_endpoint = module.eks.cluster_endpoint
  rancher_hostname = var.rancher_hostname
  rancher_password = var.rancher_password
  common_tags      = var.common_tags

  depends_on = [module.eks]
}

# =============================================================================
# ALB Module - REMOVED
# =============================================================================
# ALB module has been removed to simplify the architecture.
# Only NGINX Ingress NLB is used for public access to Rancher.
