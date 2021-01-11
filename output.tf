locals {
  configuration = {
    # Route 53
    dnsHostedZoneId = aws_route53_zone.default.zone_id
    dnsNs1 = aws_route53_zone.default.name_servers.0
    dnsNs2 = aws_route53_zone.default.name_servers.1
    dnsNs3 = aws_route53_zone.default.name_servers.2
    dnsNs4 = aws_route53_zone.default.name_servers.3

    # account 
    externalAccountId = data.aws_caller_identity.current.account_id
    region            = var.region

    # security
    keyPair          = var.keyPair

    # Network
    vpcId            = aws_vpc.default.id
    publicSubnet1Id  = aws_subnet.public-1.id
    publicSubnet2Id  = aws_subnet.public-2.id
    privateSubnet1Id = aws_subnet.private-1.id
    privateSubnet2Id = aws_subnet.private-2.id

    # ALB
    albEndpoint    = aws_lb.default.dns_name
    albListenerArn = aws_alb_listener.default.arn

    # bucket
    bucketName = var.bucket

    # instance
    instanceSecurityGroup = aws_security_group.instance.id
    instanceProfile = aws_iam_instance_profile.instance.name
  }
}

resource "local_file" "configuration" {
  content  = jsonencode(local.configuration)
  filename = "${path.module}/dist/${var.cloudRegionId}.json"

provisioner "local-exec" {
    command = <<EOT
        curl -X POST http://localhost/api/region-manager-aws/register/postupsert \
                -H 'Content-Type: application/json' \
                -H 'cloudRegionId: ${var.cloudRegionId}' \
                -H 'shortId: ${var.shortId}' \
                -d @${path.module}/dist/${var.cloudRegionId}.json 
EOT
  }

}

