resource "aws_iam_role" "livy-lambda" {
  name = "isthari-${var.shortId}-livy-lambda"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

# IAM Policy
resource "aws_iam_policy" "livy-lambda" {
  name        = "isthari-${var.shortId}-livy-lambda"
  path        = "/"
  description = "Isthari ${var.shortId} Livy Lambda"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ],
      "Resource": "arn:aws:logs:*:*",
      "Effect": "Allow"
    },
    {
      "Action": [
        "ec2:CreateNetworkInterface",
        "ec2:DescribeNetworkInterfaces",
        "ec2:DeleteNetworkInterface"
      ],
      "Effect": "Allow",
      "Resource": "*"
    }
  ]
}
EOF
}

# cloudwatch log group
resource "aws_cloudwatch_log_group" "lambda" {
  name              = "/aws/lambda/${aws_lambda_function.livy.function_name}"
  retention_in_days = var.retentionInDays
}

# attach policy
resource "aws_iam_role_policy_attachment" "livy-lambda" {
  role       = aws_iam_role.livy-lambda.name
  policy_arn = aws_iam_policy.livy-lambda.arn
}

data "archive_file" "livy-lambda" {
  type        = "zip"
  source_dir  = "${path.module}/js/livy"
  output_path = "${path.module}/dist/livy.zip"
}

resource "aws_lambda_function" "livy" {
  filename         = "${path.module}/dist/livy.zip"
  function_name    = "isthari-${var.shortId}-livy"
  role             = aws_iam_role.livy-lambda.arn
  handler          = "exports.handler"
  source_code_hash = data.archive_file.livy-lambda.output_base64sha256
  runtime          = "nodejs12.x"
  timeout          = 300

  vpc_config {
    subnet_ids         = [aws_subnet.private-1.id, aws_subnet.private-2.id]
    security_group_ids = [ aws_security_group.lambda.id ]
  }
}

# añadir la funcion lambda al alb
resource "aws_lb_target_group" "livy" {
  name        = "isthari-${var.shortId}-livy"
  target_type = "lambda"
}

# invoke lambda from lb
resource "aws_lambda_permission" "livy" {
  statement_id  = "AllowExecutionFromlb"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.livy.arn
  principal     = "elasticloadbalancing.amazonaws.com"
  source_arn    = aws_lb_target_group.livy.arn
}

# target group -> lambda
resource "aws_lb_target_group_attachment" "livy" {
  target_group_arn = aws_lb_target_group.livy.arn
  target_id        = aws_lambda_function.livy.arn
  depends_on       = [aws_lambda_permission.livy]
}

# listener rule
resource "aws_lb_listener_rule" "livy" {
  listener_arn = aws_alb_listener.default.arn
  priority     = 997

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.livy.arn
  }

  condition {
    host_header {
      values = [ "livy-*.${var.shortId}.cloud.isthari.com" ]
    }
  }
}

