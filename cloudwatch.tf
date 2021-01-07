resource "aws_cloudwatch_event_rule" "EC2" {
  name = "isthari-${var.shortId}-EC2"
  event_pattern = <<PATTERN
{
  "source": [
    "aws.ec2"
  ],
  "detail-type": [
    "EC2 Instance State-change Notification"
  ]
}
PATTERN
}

resource "aws_iam_role" "cloudwatch-events" {
  name = "isthari-${var.shortId}-cloudwatch-events"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "events.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_policy" "cloudwatch-events" {
  name = "isthari-${var.shortId}-cloudwatch-events"
  path = "/"
  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "events:PutEvents"
            ],
            "Resource": [
                "arn:aws:events:${var.region}:840227551083:event-bus/default"
            ]
        }
    ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "cloudwatch-events" {
  role       = aws_iam_role.cloudwatch-events.name
  policy_arn = aws_iam_policy.cloudwatch-events.arn
}

resource "aws_cloudwatch_event_target" "EC2" {
  rule     = aws_cloudwatch_event_rule.EC2.name
  arn      = "arn:aws:events:${var.region}:840227551083:event-bus/default"
  role_arn = aws_iam_role.cloudwatch-events.arn
}

