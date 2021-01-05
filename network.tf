# VPC
resource "aws_vpc" "default" {
  cidr_block                       = var.vpc_net
  assign_generated_ipv6_cidr_block = false
  tags = {
    Name = "isthari-${var.shortId}"
  }
}

# Subnets
resource "aws_subnet" "public-1" {
  vpc_id                          = aws_vpc.default.id
  cidr_block                      = var.vpc_public_1_net
  availability_zone               = "${var.region}a"
  assign_ipv6_address_on_creation = false
  map_public_ip_on_launch         = true
  tags = {
    Name = "isthari-${var.shortId}-public-1"
  }
}

resource "aws_subnet" "public-2" {
  vpc_id                          = aws_vpc.default.id
  cidr_block                      = var.vpc_public_2_net
  availability_zone               = "${var.region}b"
  assign_ipv6_address_on_creation = false
  map_public_ip_on_launch         = true
  tags = {
    Name = "isthari-${var.shortId}-public-2"
  }
}

# Internet gateway
resource "aws_internet_gateway" "default" {
  vpc_id = aws_vpc.default.id
  tags = {
    Name = "isthari-${var.shortId}"
  }
}

# Route table
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.default.id
  tags = {
    Name      = "isthari-${var.shortId}-public"
  }

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.default.id
  }
}

# Associate to route table
resource "aws_route_table_association" "public-1" {
  subnet_id      = aws_subnet.public-1.id
  route_table_id = aws_route_table.public.id
}
resource "aws_route_table_association" "public-2" {
  subnet_id      = aws_subnet.public-2.id
  route_table_id = aws_route_table.public.id
}

