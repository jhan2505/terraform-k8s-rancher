# =============================================================================
# ALB Module Outputs
# =============================================================================

output "alb_arn" {
  description = "ARN of the Application Load Balancer"
  value       = aws_lb.rancher.arn
}

output "alb_dns_name" {
  description = "DNS name of the Application Load Balancer"
  value       = aws_lb.rancher.dns_name
}

output "alb_zone_id" {
  description = "Zone ID of the Application Load Balancer"
  value       = aws_lb.rancher.zone_id
}

output "target_group_arn" {
  description = "ARN of the target group"
  value       = aws_lb_target_group.rancher.arn
}

output "rancher_url" {
  description = "URL to access Rancher"
  value       = var.rancher_domain != "" ? "http://${var.rancher_domain}" : "http://${aws_lb.rancher.dns_name}"
}

output "ssl_certificate_arn" {
  description = "ARN of the SSL certificate"
  value       = var.enable_ssl ? aws_acm_certificate.rancher[0].arn : null
}
