
# 1. Create VPC
resource "aws_vpc" "alfa_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "alfa-vpc"
  }
}

# 2. Create Public Subnet
resource "aws_subnet" "public_subnet_1a" {
  vpc_id                  = aws_vpc.alfa_vpc.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true

  tags = {
    Name = "alfa-public-subnet"
  }
}

# 3. Create Private Subnet
resource "aws_subnet" "private_subnet_1a" {
  vpc_id            = aws_vpc.alfa_vpc.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "us-east-1a"

  tags = {
    Name = "alfa-private-subnet"
  }
}

# 4. Create Internet Gateway
resource "aws_internet_gateway" "alfa_igw" {
  vpc_id = aws_vpc.alfa_vpc.id

  tags = {
    Name = "alfa-igw"
  }
}

# 5. Create Elastic IP
resource "aws_eip" "alfa_eip" {
  domain = "vpc"

  tags = {
    Name = "alfa-nat-eip"
  }
}

# 6. Create NAT Gateway in Public Subnet
resource "aws_nat_gateway" "alfa_nat" {
  allocation_id = aws_eip.alfa_eip.id
  subnet_id     = aws_subnet.public_subnet_1a.id

  depends_on = [
    aws_internet_gateway.alfa_igw
  ]

  tags = {
    Name = "alfa-nat-gateway"
  }
}

# 7. Create Public Route Table
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.alfa_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.alfa_igw.id
  }

  tags = {
    Name = "alfa-public-rt"
  }
}

# 8. Associate Public Route Table
resource "aws_route_table_association" "public_assoc" {
  subnet_id      = aws_subnet.public_subnet_1a.id
  route_table_id = aws_route_table.public_rt.id
}

# 9. Create Private Route Table
resource "aws_route_table" "private_rt" {
  vpc_id = aws_vpc.alfa_vpc.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.alfa_nat.id
  }

  tags = {
    Name = "alfa-private-rt"
  }
}

# 10. Associate Private Route Table
resource "aws_route_table_association" "private_assoc" {
  subnet_id      = aws_subnet.private_subnet_1a.id
  route_table_id = aws_route_table.private_rt.id
}
