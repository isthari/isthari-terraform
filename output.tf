locals {
  configuration = {
    dnsHostedZoneId = aws_route53_zone.default.zone_id
    dnsNs1 = aws_route53_zone.default.name_servers.0
    dnsNs2 = aws_route53_zone.default.name_servers.1
    dnsNs3 = aws_route53_zone.default.name_servers.2
    dnsNs4 = aws_route53_zone.default.name_servers.3

    vpcId            = aws_vpc.default.id
    publicSubnet1id  = aws_subnet.public-1.id
    publicSubnet2id  = aws_subnet.public-2.id
    privateSubnet1id = aws_subnet.private-1.id
  }
}

resource "local_file" "configuration" {
  content  = jsonencode(local.configuration)
  filename = "${path.module}/dist/${var.cloudRegionId}.json"
}

