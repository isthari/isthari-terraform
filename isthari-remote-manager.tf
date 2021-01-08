# role
resource "aws_iam_role" "isthari-remote-manager" {
  name = "isthari-${var.shortId}-remote-manager"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "AWS": "arn:aws:iam::840227551083:root",
        "AWS": "arn:aws:iam::840227551083:role/isthari-remote-manager"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

# not need to be removed
#resource "aws_iam_instance_profile" "isthari-remote-manager" {
#  name = "isthari-${var.shortId}-remote-manager"
#  role = aws_iam_role.isthari-remote-manager.name
#}

# Access to route 53
resource "aws_iam_policy" "isthari-remote-manager-route53" {
  name        = "isthari-${var.shortId}-remote-manager-route53"
  path        = "/"
  description = "Register new instances in route 53"
  policy      = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": "route53:ChangeResourceRecordSets",
      "Resource": "arn:aws:route53:::hostedzone/${aws_route53_zone.default.id}"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "isthari-remote-manager-route53" {
  policy_arn = aws_iam_policy.isthari-remote-manager-route53.arn
  role       = aws_iam_role.isthari-remote-manager.name
}

# Access to EC2
resource "aws_iam_policy" "isthari-remote-manager-EC2" {
  name        = "isthari-${var.shortId}-remote-manager-EC2"
  path        = "/"
  description = "Access to EC2"
  policy      = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
      	"ec2:CreateTags",
        "ec2:DescribeInstances",
        "ec2:RunInstances",
        "ec2:TerminateInstances",
        "iam:PassRole",
        "iam:ListInstanceProfiles"
      ],
      "Resource": "*"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "isthari-remote-manager-EC2" {
  policy_arn = aws_iam_policy.isthari-remote-manager-EC2.arn
  role       = aws_iam_role.isthari-remote-manager.name
}
