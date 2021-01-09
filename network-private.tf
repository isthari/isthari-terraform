# subnets
resource "aws_subnet" "private-1" {
  vpc_id            = aws_vpc.default.id
  cidr_block        = var.vpc_private_1_net
  availability_zone = "${var.region}a"
  tags              = {
    Name = "isthari-${var.shortId}-private-1"
  }
}
resource "aws_subnet" "private-2" {
  vpc_id            = aws_vpc.default.id
  cidr_block        = var.vpc_private_2_net
  availability_zone = "${var.region}b"
  tags              = {
    Name = "isthari-${var.shortId}-private-2"
  }
}

# eip
resource "aws_eip" "public-1" {
  vpc = true
}
resource "aws_eip" "public-2" {
  vpc = true
}

# nat gateway
resource "aws_nat_gateway" "public-1" {
  allocation_id = aws_eip.public-1.id
  subnet_id     = aws_subnet.public-1.id
  depends_on    = [ aws_eip.public-1 ]
  tags          = {
    Name = "isthari-${var.shortId}-public-1"
  }
}
resource "aws_nat_gateway" "public-2" {
  allocation_id = aws_eip.public-2.id
  subnet_id     = aws_subnet.public-2.id
  depends_on    = [ aws_eip.public-2 ]
  tags          = {
    Name = "isthari-${var.shortId}-public-2"
  }
}

# route tables
resource "aws_route_table" "private-1" {
  vpc_id = aws_vpc.default.id
  tags = {
    Name = "isthari-${var.shortId}-private-1"
  }
}
resource "aws_route_table" "private-2" {
  vpc_id = aws_vpc.default.id
  tags = {
    Name = "isthari-${var.shortId}-private-2"
  }
}

# route table association
resource "aws_route_table_association" "private-1-nat" {
  subnet_id      = aws_subnet.private-1.id
  route_table_id = aws_route_table.private-1.id
}
resource "aws_route_table_association" "private-2-nat" {
  subnet_id      = aws_subnet.private-2.id
  route_table_id = aws_route_table.private-2.id
}

# routes
resource "aws_route" "private-1-nat" {
  route_table_id         = aws_route_table.private-1.id
  nat_gateway_id         = aws_nat_gateway.public-1.id
  destination_cidr_block = "0.0.0.0/0"
}
resource "aws_route" "private-2-nat" {
  route_table_id         = aws_route_table.private-2.id
  nat_gateway_id         = aws_nat_gateway.public-2.id
  destination_cidr_block = "0.0.0.0/0"
}

