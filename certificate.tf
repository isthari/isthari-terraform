resource "aws_acm_certificate" "wildcard" {
  domain_name       = "*.${var.shortId}.cloud.isthari.com"
  validation_method = "DNS"
  tags = {
    Name = "wilcard.${var.shortId}.cloud.isthari.com"
  }
  lifecycle {
    create_before_destroy = true
  }
}
resource "aws_route53_record" "cert_validation_wildcard" {
  name    = aws_acm_certificate.wildcard.domain_validation_options.0.resource_record_name
  type    = aws_acm_certificate.wildcard.domain_validation_options.0.resource_record_type
  zone_id = aws_route53_zone.default.zone_id
  records = [aws_acm_certificate.wildcard.domain_validation_options.0.resource_record_value]
  ttl     = 60
}

