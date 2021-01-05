resource "aws_route53_zone" "default" {
  name          = "${var.shortId}.cloud.isthari.com"
  force_destroy = true
}

