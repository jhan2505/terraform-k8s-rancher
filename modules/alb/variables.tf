# =============================================================================
# ALB Module Variables
# =============================================================================

variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "vpc_id" {
  description = "ID of the VPC"
  type        = string
}

variable "public_subnet_ids" {
  description = "List of public subnet IDs"
  type        = list(string)
}

variable "eks_security_group_id" {
  description = "ID of the EKS security group"
  type        = string
}

variable "rancher_domain" {
  description = "Domain name for Rancher (optional)"
  type        = string
  default     = ""
}

variable "route53_zone_id" {
  description = "Route 53 hosted zone ID (optional)"
  type        = string
  default     = ""
}

variable "enable_ssl" {
  description = "Enable SSL/TLS for Rancher"
  type        = bool
  default     = false
}

variable "common_tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default     = {}
}
