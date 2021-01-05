
resource "aws_subnet" "private-1" {
  vpc_id            = aws_vpc.default.id
  cidr_block        = var.vpc_private_1_net
  availability_zone = "${var.region}a"
  tags              = {
    Name = "isthari-${var.shortId}-private-1"
  }
}

resource "aws_eip" "public-1" {
  vpc = true
}

resource "aws_nat_gateway" "public-1" {
  allocation_id = aws_eip.public-1.id
  subnet_id     = aws_subnet.public-1.id
  depends_on    = [ aws_eip.public-1 ]
  tags          = {
    Name = "isthari-${var.shortId}-public-1"
  }
}

resource "aws_route_table" "private-1" {
  vpc_id = aws_vpc.default.id
  tags = {
    Name = "isthari-${var.shortId}-private-1"
  }
}

resource "aws_route_table_association" "private-1-nat" {
  subnet_id      = aws_subnet.private-1.id
  route_table_id = aws_route_table.private-1.id
}

resource "aws_route" "private-1-nat" {
  route_table_id         = aws_route_table.private-1.id
  nat_gateway_id         = aws_nat_gateway.public-1.id
  destination_cidr_block = "0.0.0.0/0"
}

