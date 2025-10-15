# =============================================================================
# Variables - Eventim DevOps Challenge
# =============================================================================

# =============================================================================
# General Configuration
# =============================================================================

variable "project_name" {
  description = "Name of the project"
  type        = string
  default     = "eventim-devops"
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  default     = "dev"
}

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-west-2"
}

# =============================================================================
# VPC Configuration
# =============================================================================

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

# =============================================================================
# Security Configuration - REMOVED
# =============================================================================
# Removed allowed_ssh_ips variable - not needed since nodes are in private subnets

# =============================================================================
# EKS Configuration
# =============================================================================

variable "cluster_version" {
  description = "Kubernetes version for EKS cluster"
  type        = string
  default     = "1.28"
}

variable "node_group_instance_types" {
  description = "Instance types for EKS node group"
  type        = list(string)
  default     = ["t3.medium"]
}

variable "node_group_desired_size" {
  description = "Desired number of nodes in EKS node group"
  type        = number
  default     = 2
}

variable "node_group_max_size" {
  description = "Maximum number of nodes in EKS node group"
  type        = number
  default     = 4
}

variable "node_group_min_size" {
  description = "Minimum number of nodes in EKS node group"
  type        = number
  default     = 1
}

# =============================================================================
# Rancher Configuration
# =============================================================================

variable "rancher_hostname" {
  description = "Hostname for Rancher UI"
  type        = string
  default     = "rancher.local"
}

variable "rancher_password" {
  description = "Password for Rancher admin user"
  type        = string
  default     = "admin123!"
  sensitive   = true
}

# =============================================================================
# Public Access Configuration
# =============================================================================

variable "enable_public_access" {
  description = "Enable public access to Rancher via NGINX Ingress NLB"
  type        = bool
  default     = false
}

# =============================================================================
# Common Tags
# =============================================================================

variable "common_tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default = {
    Project     = "EventimDevOps"
    Environment = "dev"
    ManagedBy   = "Terraform"
    Owner       = "DevOps Team"
  }
}
