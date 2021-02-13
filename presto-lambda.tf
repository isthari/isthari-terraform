resource "aws_iam_role" "presto-lambda" {
  name = "isthari-${var.shortId}-presto-lambda"
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
resource "aws_iam_policy" "presto-lambda" {
  name        = "isthari-${var.shortId}-presto-lambda"
  path        = "/"
  description = "Isthari ${var.shortId} Presto Lambda"

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
      "Resource": "arn:aws:logs:*:*:*",
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
resource "aws_cloudwatch_log_group" "presto" {
  name              = "/aws/lambda/${aws_lambda_function.presto.function_name}"
  retention_in_days = var.retentionInDays 
}

# attach policy
resource "aws_iam_role_policy_attachment" "presto-lambda" {
  role       = aws_iam_role.presto-lambda.name
  policy_arn = aws_iam_policy.presto-lambda.arn
}

data "archive_file" "presto-lambda" {
  type        = "zip"
  source_dir  = "${path.module}/js/presto"
  output_path = "${path.module}/dist/presto.zip"
}

resource "aws_lambda_function" "presto" {
  filename         = "${path.module}/dist/presto.zip"
  function_name    = "isthari-${var.shortId}-presto"
  role             = aws_iam_role.presto-lambda.arn
  handler          = "exports.handler"
  source_code_hash = data.archive_file.presto-lambda.output_base64sha256 
  runtime          = "nodejs12.x"
  timeout          = 300

  vpc_config {
    subnet_ids         = [aws_subnet.private-1.id]
    security_group_ids = [ aws_security_group.lambda.id ]
  }
}

# añadir la funcion lambda al alb
resource "aws_lb_target_group" "presto" {
  name        = "isthari-${var.shortId}-presto"
  target_type = "lambda"
}

# invoke lambda from lb
resource "aws_lambda_permission" "presto" {
  statement_id  = "AllowExecutionFromlb"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.presto.arn
  principal     = "elasticloadbalancing.amazonaws.com"
  source_arn    = aws_lb_target_group.presto.arn
}

# target group -> lambda
resource "aws_lb_target_group_attachment" "presto" {
  target_group_arn = aws_lb_target_group.presto.arn
  target_id        = aws_lambda_function.presto.arn
  depends_on       = [aws_lambda_permission.presto]
}

# listener rule
resource "aws_lb_listener_rule" "presto" {
  listener_arn = aws_alb_listener.default.arn
  priority     = 998

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.presto.arn
  }

  condition {
    host_header {
      values = [ "presto-master-*.${var.shortId}.cloud.isthari.com" ]
    }
  }
}


