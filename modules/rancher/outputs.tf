# =============================================================================
# Rancher Module Outputs
# =============================================================================

output "rancher_url" {
  description = "URL to access Rancher UI"
  value       = "https://${var.rancher_hostname}"
}

output "rancher_namespace" {
  description = "Kubernetes namespace where Rancher is deployed"
  value       = kubernetes_namespace.cattle_system.metadata[0].name
}

output "rancher_admin_password_secret" {
  description = "Name of the Kubernetes secret containing Rancher admin password"
  value       = kubernetes_secret.rancher_admin_password.metadata[0].name
}

output "nginx_ingress_service" {
  description = "Name of the NGINX Ingress service"
  value       = helm_release.nginx_ingress.name
}

output "rancher_status" {
  description = "Status of the Rancher Helm release"
  value       = helm_release.rancher.status
}

output "nginx_ingress_status" {
  description = "Status of the NGINX Ingress Helm release"
  value       = helm_release.nginx_ingress.status
}

output "rancher_ingress_name" {
  description = "Name of the Rancher Ingress resource"
  value       = kubernetes_ingress_v1.rancher_public.metadata[0].name
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
