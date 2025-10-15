# =============================================================================
# Outputs - Eventim DevOps Challenge
# =============================================================================

# =============================================================================
# VPC Outputs
# =============================================================================

output "vpc_id" {
  description = "ID of the VPC"
  value       = module.vpc.vpc_id
}

output "vpc_cidr_block" {
  description = "CIDR block of the VPC"
  value       = module.vpc.vpc_cidr_block
}

output "private_subnet_ids" {
  description = "IDs of the private subnets"
  value       = module.vpc.private_subnet_ids
}

output "public_subnet_ids" {
  description = "IDs of the public subnets"
  value       = module.vpc.public_subnet_ids
}

# =============================================================================
# EKS Outputs
# =============================================================================

output "cluster_name" {
  description = "Name of the EKS cluster"
  value       = module.eks.cluster_name
}

output "cluster_endpoint" {
  description = "Endpoint for EKS cluster"
  value       = module.eks.cluster_endpoint
}

output "cluster_security_group_id" {
  description = "Security group ID of the EKS cluster"
  value       = module.eks.cluster_security_group_id
}

output "cluster_certificate_authority_data" {
  description = "Certificate authority data for EKS cluster"
  value       = module.eks.cluster_certificate_authority_data
}

# =============================================================================
# Rancher Outputs
# =============================================================================

output "rancher_url" {
  description = "URL to access Rancher UI"
  value       = var.enable_public_access ? "Use NGINX Ingress Load Balancer (see rancher_public_access_instructions)" : "Use port-forward (see rancher_access_instructions)"
}

output "rancher_admin_password" {
  description = "Admin password for Rancher (stored in Kubernetes secret)"
  value       = "Check Kubernetes secret 'rancher-admin-password'"
  sensitive   = true
}

# =============================================================================
# ALB Outputs - REMOVED
# =============================================================================
# ALB outputs have been removed as the ALB module is no longer used.
# Only NGINX Ingress NLB is used for public access to Rancher.

# =============================================================================
# Connection Information
# =============================================================================

output "kubectl_config_command" {
  description = "Command to configure kubectl"
  value       = "aws eks update-kubeconfig --region ${var.aws_region} --name ${module.eks.cluster_name}"
}

output "rancher_access_instructions" {
  description = "Instructions to access Rancher"
  value = <<-EOT
    1. Configure kubectl: aws eks update-kubeconfig --region ${var.aws_region} --name ${module.eks.cluster_name}
    2. Port forward to Rancher: kubectl port-forward -n cattle-system svc/rancher 8080:80 8443:443
    3. Access Rancher UI: https://localhost:8443
    4. Username: admin
    5. Password: Check Kubernetes secret 'rancher-admin-password'
  EOT
}

output "rancher_load_balancer_dns" {
  description = "DNS name of the NGINX Ingress Load Balancer for Rancher"
  value       = "Get with: kubectl get svc -n cattle-system nginx-ingress-ingress-nginx-controller"
}

output "rancher_public_access_instructions" {
  description = "Instructions for accessing Rancher via Load Balancer"
  value = <<-EOT
    Rancher is accessible via the NGINX Ingress Load Balancer:
    
    1. Get Load Balancer DNS:
       kubectl get svc -n cattle-system nginx-ingress-ingress-nginx-controller
    
    2. Access Rancher UI:
       https://<LOAD_BALANCER_DNS>
    
    3. Login credentials:
       Username: admin
       Password: admin123!
    
    4. Note: Accept the self-signed certificate in your browser
  EOT
}
