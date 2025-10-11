# =============================================================================
# Security Groups Module Outputs
# =============================================================================

output "eks_security_group_id" {
  description = "ID of the EKS cluster security group"
  value       = aws_security_group.eks_cluster.id
}

output "eks_nodes_security_group_id" {
  description = "ID of the EKS nodes security group"
  value       = aws_security_group.eks_nodes.id
}

output "rancher_lb_security_group_id" {
  description = "ID of the Rancher load balancer security group"
  value       = aws_security_group.rancher_lb.id
}
