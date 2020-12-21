resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "terraform-101"
  }

}
#public subnet 생성
resource "aws_subnet" "public_subnet" {
  vpc_id = aws_vpc.main.id
  cidr_block = "10.0.0.0/24"

  availability_zone = "ap-northeast-2a"

  tags = {
     Name = "terraform-101-public-subnet"
  }
}
# private subnet 생성
resource "aws_subnet" "private_subnet" {
  vpc_id = aws_vpc.main.id
  cidr_block = "10.0.10.0/24"

  tags = {
   Name = "terraform-101-private-subnet"
  }
}
# internet gateway 생성
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id

  tags = {
   Name = "terraform-101-igw"
  }

}
# nat gateway 생성
resource "aws_eip" "nat" {
  vpc   = true

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_nat_gateway" "nat_gateway" {
  allocation_id = aws_eip.nat.id

  # Private subnet이 아니라 public subnet을 연결하셔야 합니다.
  subnet_id = aws_subnet.public_subnet.id

  tags = {
    Name = "terraform-NATGW"
  }
}
# public route table
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
  # ingress 형태로 rule 삽입, inner rule (association과 동일)
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "terraform-101-rt-public"
  }

}
# private route table
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "terraform-101-rt-private"
  }

}
# public route table association
resource "aws_route_table_association" "route_table_association_public" {
  subnet_id      = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.public.id
}


# private route table association
resource "aws_route_table_association" "route_table_association_private" {
  subnet_id      = aws_subnet.private_subnet.id
  route_table_id = aws_route_table.private.id
}
# route table rule 추가 nat gateway에 연결
resource "aws_route" "private_nat" {
  route_table_id              = aws_route_table.private.id
  destination_cidr_block      = "0.0.0.0/0"
  nat_gateway_id              = aws_nat_gateway.nat_gateway.id
}

