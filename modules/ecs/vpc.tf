####################
# vpc
####################
resource "aws_vpc" "main" {
  cidr_block           = var.vpc
  enable_dns_hostnames = true
  enable_dns_support   = true
  tags = {
    Name = "${var.project_name}-vpc"
  }
}

####################
# subnet
####################
resource "aws_subnet" "public_1a" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.public_subnet
  availability_zone = "ap-northeast-1a"
  tags = {
    Name = "${var.project_name}-public-1a"
  }
}

# プライベートサブネット作成
resource "aws_subnet" "private_1a" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_subnet
  availability_zone = "ap-northeast-1a"
  tags = {
    Name = "${var.project_name}-private-1a"
  }
}

####################
# internet gateway
####################
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "${var.project_name}-igw"
  }
}

####################
# route table
####################
# public_ルートテーブル作成
resource "aws_route_table" "public_1a" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "${var.project_name}-public-1a"
  }
}

# private_ルートテーブル作成
resource "aws_route_table" "private_1a" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "${var.project_name}-private-1a"
  }
}

# public_ルート作成
resource "aws_route" "public_igw_1a" {
  destination_cidr_block = "0.0.0.0/0"
  route_table_id         = aws_route_table.public_1a.id
  gateway_id             = aws_internet_gateway.main.id
}

# private_ルート作成
resource "aws_route" "nat_1a" {
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.nat_1a.id
  route_table_id         = aws_route_table.private_1a.id
}

# public_ルートテーブル紐づけ
resource "aws_route_table_association" "public_1a" {
  subnet_id      = aws_subnet.public_1a.id
  route_table_id = aws_route_table.public_1a.id
}

# private_ルートテーブル紐づけ
resource "aws_route_table_association" "private_1a" {
  subnet_id      = aws_subnet.private_1a.id
  route_table_id = aws_route_table.private_1a.id
}

####################
# nat gateway
####################
# NATゲートウェイ(AZ-1a)に割り当てるEIPを作成
resource "aws_eip" "nat_1a" {
  domain = "vpc"
  tags = {
    Name = "${var.project_name}-nat-1a"
  }
}

# NATゲートウェイ(AZ-1a)作成
resource "aws_nat_gateway" "nat_1a" {
  allocation_id = aws_eip.nat_1a.id
  subnet_id     = aws_subnet.public_1a.id
  depends_on    = [aws_internet_gateway.main]
  tags = {
    Name = "${var.project_name}-ngw-1a"
  }
}
