resource "aws_security_group" "lambda"{
  name        = "isthari-${var.shortId}-lambda"
  description = "isthari-${var.shortId}-lambda"
  vpc_id      = aws_vpc.default.id
  ingress {
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    security_groups = [ aws_security_group.alb.id ]
  }

  egress {
    from_port       = 0
    to_port         = 65535
    protocol        = "tcp"
    cidr_blocks     = ["0.0.0.0/0"]
  }

  tags = {
    Name = "isthari-${var.shortId}-lambda"
  }
}

