# =============================================================================
# Rancher Module - Eventim DevOps Challenge
# =============================================================================

# =============================================================================
# Kubernetes Namespace for Rancher
# =============================================================================

resource "kubernetes_namespace" "cattle_system" {
  metadata {
    name = "cattle-system"
    labels = {
      "app.kubernetes.io/name"    = "rancher"
      "app.kubernetes.io/part-of" = "rancher"
    }
    annotations = {
      "lifecycle.cattle.io/create.namespace-auth" = "true"
    }
  }

  # Ensure proper cleanup on destroy
  lifecycle {
    create_before_destroy = true
  }
}

# =============================================================================
# Rancher Helm Repository
# =============================================================================

resource "helm_release" "rancher" {
  name       = "rancher"
  repository = "https://releases.rancher.com/server-charts/latest"
  chart      = "rancher"
  namespace  = kubernetes_namespace.cattle_system.metadata[0].name
  version    = "2.12.2"

  set {
    name  = "hostname"
    value = var.rancher_hostname
  }

  set {
    name  = "bootstrapPassword"
    value = var.rancher_password
  }

  set {
    name  = "replicas"
    value = "1"
  }

  set {
    name  = "ingress.tls.source"
    value = "secret"
  }

  # Disable problematic features that cause destroy issues
  set {
    name  = "monitoring.enabled"
    value = "false" # Disable to avoid cleanup issues
  }

  set {
    name  = "logging.enabled"
    value = "false" # Disable to avoid cleanup issues
  }

  set {
    name  = "backup.enabled"
    value = "false" # Disable to avoid cleanup issues
  }

  # Disable post-delete job that causes issues
  set {
    name  = "postDelete.enabled"
    value = "false"
  }

  depends_on = [kubernetes_namespace.cattle_system]

  timeout = 300 # Reduced timeout
  wait    = true

  # Ensure proper cleanup on destroy
  lifecycle {
    create_before_destroy = true
  }
}


# =============================================================================
# NGINX Ingress Controller
# =============================================================================

resource "helm_release" "nginx_ingress" {
  name       = "nginx-ingress"
  repository = "https://kubernetes.github.io/ingress-nginx"
  chart      = "ingress-nginx"
  namespace  = kubernetes_namespace.cattle_system.metadata[0].name
  version    = "4.8.0"

  set {
    name  = "controller.service.type"
    value = "LoadBalancer"
  }

  set {
    name  = "controller.service.annotations.service\\.beta\\.kubernetes\\.io/aws-load-balancer-type"
    value = "nlb"
  }

  set {
    name  = "controller.service.annotations.service\\.beta\\.kubernetes\\.io/aws-load-balancer-scheme"
    value = "internet-facing"
  }

  depends_on = [kubernetes_namespace.cattle_system]

  timeout = 300
  wait    = true

  # Ensure proper cleanup on destroy
  lifecycle {
    create_before_destroy = true
  }
}

# =============================================================================
# Rancher Admin Password Secret
# =============================================================================

resource "kubernetes_secret" "rancher_admin_password" {
  metadata {
    name      = "rancher-admin-password"
    namespace = kubernetes_namespace.cattle_system.metadata[0].name
  }

  data = {
    password = var.rancher_password
  }

  type = "Opaque"

  depends_on = [helm_release.rancher]
}

# =============================================================================
# Rancher Service Account for External Access
# =============================================================================

resource "kubernetes_service_account" "rancher_admin" {
  metadata {
    name      = "rancher-admin"
    namespace = kubernetes_namespace.cattle_system.metadata[0].name
  }

  depends_on = [helm_release.rancher]
}

# =============================================================================
# Rancher Cluster Role Binding
# =============================================================================

resource "kubernetes_cluster_role_binding" "rancher_admin" {
  metadata {
    name = "rancher-admin-binding"
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = "cluster-admin"
  }

  subject {
    kind      = "ServiceAccount"
    name      = kubernetes_service_account.rancher_admin.metadata[0].name
    namespace = kubernetes_namespace.cattle_system.metadata[0].name
  }

  depends_on = [kubernetes_service_account.rancher_admin]
}

# =============================================================================
# Rancher Ingress for Public Access
# =============================================================================

resource "kubernetes_ingress_v1" "rancher_public" {
  metadata {
    name      = "rancher-ingress"
    namespace = kubernetes_namespace.cattle_system.metadata[0].name
    annotations = {
      "nginx.ingress.kubernetes.io/ssl-redirect"     = "false"
      "nginx.ingress.kubernetes.io/backend-protocol" = "HTTP"
      "nginx.ingress.kubernetes.io/proxy-body-size"  = "0"
      "nginx.ingress.kubernetes.io/proxy-read-timeout" = "600"
      "nginx.ingress.kubernetes.io/proxy-send-timeout" = "600"
    }
  }

  spec {
    ingress_class_name = "nginx"
    
    rule {
      http {
        path {
          path      = "/"
          path_type = "Prefix"
          backend {
            service {
              name = "rancher"
              port {
                number = 80
              }
            }
          }
        }
      }
    }
  }

  depends_on = [
    helm_release.nginx_ingress,
    helm_release.rancher
  ]

  # Ensure proper cleanup on destroy
  lifecycle {
    create_before_destroy = true
  }
}
