resource "aws_route53_record" "metastore" {
  zone_id = aws_route53_zone.default.id
  name    = "metastore.${var.shortId}.cloud.isthari.com"
  type    = "A"
  ttl     = "300"
  records = [ aws_instance.metastore.private_ip ]
}

resource "aws_route53_record" "metastore-db" {
  zone_id = aws_route53_zone.default.id
  name    = "metastore-db.${var.shortId}.cloud.isthari.com"
  type    = "CNAME"
  ttl     = "300"
  records = [ aws_rds_cluster.metastore.endpoint ]
}
