data "aws_region" "singapore" {
}

resource "aws_vpc" "singapore_vpc" {
  cidr_block           = cidrsubnet(var.main_cidr_block, 8, var.aws_region_list_for_cidr[data.aws_region.singapore.name])
  enable_dns_hostnames = true
  tags = {
    "Name" = "singapore-vpc"
  }
}

data "aws_availability_zones" "singapore_azs" {
  filter {
    name   = "opt-in-status"
    values = ["opt-in-not-required"]
  }
}

resource "aws_subnet" "singapore_public_subnets" {
  count                   = length(data.aws_availability_zones.singapore_azs.names)
  vpc_id                  = aws_vpc.singapore_vpc.id
  availability_zone       = data.aws_availability_zones.singapore_azs.names[count.index]
  cidr_block              = cidrsubnet(aws_vpc.singapore_vpc.cidr_block, 4, count.index)
  map_public_ip_on_launch = true
  tags = {
    "Name" = "singapore-public-subnet-${count.index + 1}"
    "Tier" = "Public"
  }
}

resource "aws_subnet" "singapore_private_subnets" {
  count             = length(data.aws_availability_zones.singapore_azs.names)
  vpc_id            = aws_vpc.singapore_vpc.id
  availability_zone = data.aws_availability_zones.singapore_azs.names[count.index]
  cidr_block        = cidrsubnet(aws_vpc.singapore_vpc.cidr_block, 4, count.index + 8) // to divide the /16 subnet into half/half for public and private
  tags = {
    "Name" = "singapore-private-subnet-${count.index + 1}"
    "Tier" = "Private"
  }
}

resource "aws_internet_gateway" "singapore_igw" {
  vpc_id = aws_vpc.singapore_vpc.id

  tags = {
    "Name" = "singapore-igw"
  }
}

resource "aws_route_table" "singapore_public_route_table" {
  vpc_id = aws_vpc.singapore_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.singapore_igw.id
  }

  tags = {
    "Name" = "singapore-rtb-public"
  }
}

resource "aws_route_table" "singapore_private_route_table" {
  vpc_id = aws_vpc.singapore_vpc.id

  tags = {
    "Name" = "singapore-rtb-private"
  }
}


resource "aws_route_table_association" "singapore_public_subnets_associations" {
  count          = length(aws_subnet.singapore_public_subnets)
  subnet_id      = aws_subnet.singapore_public_subnets[count.index].id
  route_table_id = aws_route_table.singapore_public_route_table.id
}

resource "aws_route_table_association" "singapore_private_subnets_associations" {
  count          = length(aws_subnet.singapore_private_subnets)
  subnet_id      = aws_subnet.singapore_private_subnets[count.index].id
  route_table_id = aws_route_table.singapore_private_route_table.id
}
