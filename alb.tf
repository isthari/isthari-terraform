resource "aws_security_group" "alb" {
  name        = "isthari-${var.shortId}-alb"
  description = "isthari-${var.shortId}-alb"
  vpc_id      = aws_vpc.default.id
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port       = 0
    to_port         = 65535
    protocol        = "tcp"
    cidr_blocks     = ["0.0.0.0/0"]
  }

  tags = {
    Name                 = "isthari-${var.shortId}-alb"
    IsthariCloudRegionId = var.cloudRegionId
  }
}

# ALB
resource "aws_lb" "default" {
  name                       = "isthari-${var.shortId}"
  internal                   = false
  load_balancer_type         = "application"
  security_groups            = [ aws_security_group.alb.id ]
  subnets                    = [ aws_subnet.public-1.id ,aws_subnet.public-2.id ]
  enable_deletion_protection = false
  tags = {
    Name                 = "isthari-${var.shortId}",
    Isthari              = "true",
    IsthariCloudRegionId = var.cloudRegionId
  }

  depends_on = [ aws_internet_gateway.default ]
  idle_timeout = 300
}

# default listener
resource "aws_alb_listener" "default" {
  load_balancer_arn = aws_lb.default.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-FS-1-2-2019-08"
  certificate_arn   = aws_acm_certificate.wildcard.arn

  default_action {
    type = "redirect"
    redirect {
      port        = "443"
      protocol    = "HTTPS"
      host        = "saas.isthari.com"
      status_code = "HTTP_301"
    }
  }

}

