resource "aws_iam_role" "instance" {
  name               = "isthari-${var.shortId}-instance"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_instance_profile" "instance" {
  name = "isthari-${var.shortId}-instance"
  role = aws_iam_role.instance.name
}

# send events to cloud watchs
resource "aws_iam_role_policy_attachment" "instance-events" {
  role       = aws_iam_role.instance.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchEventsFullAccess"
}

# access S3 bucket
resource "aws_iam_policy" "instance-s3" {
  name        = "isthari-${var.shortId}-instance-s3"
  path        = "/"
  description = "isthari-${var.shortId}-instance-s3"
  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "ListObjectsInBucket",
            "Effect": "Allow",
            "Action": ["s3:ListBucket"],
            "Resource": ["arn:aws:s3:::${var.bucket}"]
        },
        {
            "Sid": "AllObjectActions",
            "Effect": "Allow",
            "Action": "s3:*Object",
            "Resource": ["arn:aws:s3:::${var.bucket}/*"]
        }
    ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "instance-s3" {
  role       = aws_iam_role.instance.name
  policy_arn = aws_iam_policy.instance-s3.arn
}

# write permissions in cloudwatch
resource "aws_iam_policy" "instance-logs" {
  name        = "isthari-${var.shortId}-instance-logs"
  path        = "/"
  description = "isthari-${var.shortId}-instance-logs"
  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "CloudWatchLogGroups",
            "Effect": "Allow",
            "Action": [ "logs:DescribeLogGroups", "logs:CreateLogGroup", "logs:PutRetentionPolicy" ],
            "Resource": [ "arn:aws:logs:${var.region}:${data.aws_caller_identity.current.account_id}:log-group:*" ]
        },
        {
            "Sid": "CloudWatchLogs",
            "Effect": "Allow",
            "Action": [ "logs:CreateLogStream", "logs:PutLogEvents", "logs:DecribeLogGroups" ],
            "Resource": [ "arn:aws:logs:${var.region}:${data.aws_caller_identity.current.account_id}:log-group:*:*" ]
        }

    ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "instance-logs" {
  role       = aws_iam_role.instance.name
  policy_arn = aws_iam_policy.instance-logs.arn
}
