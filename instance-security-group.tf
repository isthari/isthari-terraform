resource "aws_security_group" "instance" {
  name        = "isthari-${var.shortId}-instance"
  description = "Access to Big Data nodes"
  vpc_id      = aws_vpc.default.id

  tags = {
    Name = "isthari-${var.shortId}-instance"
  }
}

resource "aws_security_group_rule" "alb2instance" {
  description              = "ALB"
  type                     = "ingress"
  from_port                = 0
  to_port                  = 65535
  protocol                 = "tcp"
  security_group_id        = aws_security_group.instance.id
  source_security_group_id = aws_security_group.alb.id
}

resource "aws_security_group_rule" "lambda2instance" {
  description              = "Lambda"
  type                     = "ingress"
  from_port                = 0
  to_port                  = 65535
  protocol                 = "tcp"
  security_group_id        = aws_security_group.instance.id
  source_security_group_id = aws_security_group.lambda.id
}

resource "aws_security_group_rule" "instance-self" {
  description              = "Internal communication"
  type                     = "ingress"
  from_port                = 0
  to_port                  = 65535
  protocol                 = "tcp"
  security_group_id        = aws_security_group.instance.id
  source_security_group_id = aws_security_group.instance.id
}

resource "aws_security_group_rule" "instance-egress" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.instance.id
}

