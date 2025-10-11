# =============================================================================
# Application Load Balancer Module - Eventim DevOps Challenge
# =============================================================================

# =============================================================================
# Application Load Balancer
# =============================================================================

resource "aws_lb" "rancher" {
  name               = "${var.project_name}-${var.environment}-rancher-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = var.public_subnet_ids

  enable_deletion_protection = false

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-${var.environment}-rancher-alb"
    Type = "Application Load Balancer"
  })
}

# =============================================================================
# Target Group for Rancher
# =============================================================================

resource "aws_lb_target_group" "rancher" {
  name     = "${var.project_name}-${var.environment}-rancher-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = var.vpc_id

  health_check {
    enabled             = true
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 5
    interval            = 30
    path                = "/ping"
    port                = "traffic-port"
    protocol            = "HTTP"
    matcher             = "200"
  }

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-${var.environment}-rancher-tg"
    Type = "Target Group"
  })
}

# =============================================================================
# ALB Listener
# =============================================================================

resource "aws_lb_listener" "rancher_http" {
  load_balancer_arn = aws_lb.rancher.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.rancher.arn
  }
}

# HTTPS Listener (only if SSL is enabled)
resource "aws_lb_listener" "rancher_https" {
  count = var.enable_ssl ? 1 : 0
  
  load_balancer_arn = aws_lb.rancher.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS-1-2-2017-01"
  certificate_arn   = aws_acm_certificate_validation.rancher[0].certificate_arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.rancher.arn
  }
}

# =============================================================================
# SSL Certificate (only if SSL is enabled)
# =============================================================================

resource "aws_acm_certificate" "rancher" {
  count = var.enable_ssl ? 1 : 0
  
  domain_name       = var.rancher_domain
  validation_method = "DNS"

  subject_alternative_names = [
    "*.${var.rancher_domain}"
  ]

  lifecycle {
    create_before_destroy = true
  }

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-${var.environment}-rancher-cert"
    Type = "SSL Certificate"
  })
}

resource "aws_acm_certificate_validation" "rancher" {
  count = var.enable_ssl ? 1 : 0
  
  certificate_arn         = aws_acm_certificate.rancher[0].arn
  validation_record_fqdns = [for record in aws_route53_record.rancher_validation : record.fqdn]

  timeouts {
    create = "5m"
  }
}

# =============================================================================
# Route 53 Records (only if domain is provided)
# =============================================================================

resource "aws_route53_record" "rancher" {
  count = var.rancher_domain != "" ? 1 : 0
  
  zone_id = var.route53_zone_id
  name    = var.rancher_domain
  type    = "A"

  alias {
    name                   = aws_lb.rancher.dns_name
    zone_id                = aws_lb.rancher.zone_id
    evaluate_target_health = true
  }
}

resource "aws_route53_record" "rancher_validation" {
  for_each = var.enable_ssl && var.rancher_domain != "" ? {
    for dvo in aws_acm_certificate.rancher[0].domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  } : {}

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = var.route53_zone_id
}

# =============================================================================
# Security Group for ALB
# =============================================================================

resource "aws_security_group" "alb" {
  name_prefix = "${var.project_name}-${var.environment}-alb-"
  vpc_id      = var.vpc_id

  # Allow HTTP traffic
  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow HTTPS traffic
  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow all outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-${var.environment}-alb-sg"
    Type = "Security Group"
  })
}

# =============================================================================
# Security Group Rule for ALB to EKS
# =============================================================================

resource "aws_security_group_rule" "alb_to_eks" {
  type                     = "ingress"
  from_port                = 80
  to_port                  = 80
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.alb.id
  security_group_id        = var.eks_security_group_id
  description              = "Allow ALB to communicate with EKS"
}
