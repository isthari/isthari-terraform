resource "aws_route53_zone" "default" {
  name          = "${var.shortId}.cloud.isthari.com"
  force_destroy = true

  provisioner "local-exec" {
    command = <<EOT
	curl -X POST http://localhost/api/region-manager-aws/register/preupsert \
		-H 'Content-Type: application/json' \
		-H 'cloudRegionId: ${var.cloudRegionId}' \
		-H 'shortId: ${var.shortId}' \
		-d ' 
{
    "dnsHostedZoneId" : "${aws_route53_zone.default.zone_id}",
    "dnsNs1" : "${aws_route53_zone.default.name_servers.0}",
    "dnsNs2" : "${aws_route53_zone.default.name_servers.1}",
    "dnsNs3" : "${aws_route53_zone.default.name_servers.2}",
    "dnsNs4" : "${aws_route53_zone.default.name_servers.3}",
    "accountId": "${data.aws_caller_identity.current.account_id}"
}'
EOT
  }
}

