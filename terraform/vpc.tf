resource "aws_vpc" "staging_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = {
    Name = "staging-vpc"
  }
}

resource "aws_subnet" "staging_subnet" {
  vpc_id                  = aws_vpc.staging_vpc.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "${var.aws_region}a"
  map_public_ip_on_launch = true
  tags = {
    Name = "staging-public-1"
  }
}

resource "aws_subnet" "staging_subnet_2" {
  vpc_id                  = aws_vpc.staging_vpc.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "${var.aws_region}b"
  map_public_ip_on_launch = true
  tags = {
    Name = "staging-public-2"
  }
}

resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.staging_vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.staging_igw.id
  }
}

resource "aws_route_table_association" "pub_1" {
  subnet_id      = aws_subnet.staging_subnet.id
  route_table_id = aws_route_table.public_rt.id
}

resource "aws_route_table_association" "pub_2" {
  subnet_id      = aws_subnet.staging_subnet_2.id
  route_table_id = aws_route_table.public_rt.id
}
