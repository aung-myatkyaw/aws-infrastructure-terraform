data "aws_region" "mumbai" {
  provider = aws.mumbai
}

resource "aws_vpc" "mumbai_vpc" {
  provider             = aws.mumbai
  cidr_block           = cidrsubnet(var.main_cidr_block, 8, var.aws_region_list_for_cidr[data.aws_region.mumbai.name])
  enable_dns_hostnames = true
  tags = {
    "Name" = "${data.aws_region.mumbai.name}-vpc"
  }
}

data "aws_availability_zones" "mumbai_azs" {
  provider = aws.mumbai
  filter {
    name   = "opt-in-status"
    values = ["opt-in-not-required"]
  }
}

resource "aws_subnet" "mumbai_public_subnets" {
  provider                = aws.mumbai
  count                   = length(data.aws_availability_zones.mumbai_azs.names)
  vpc_id                  = aws_vpc.mumbai_vpc.id
  availability_zone       = data.aws_availability_zones.mumbai_azs.names[count.index]
  cidr_block              = cidrsubnet(aws_vpc.mumbai_vpc.cidr_block, 4, count.index)
  map_public_ip_on_launch = true
  tags = {
    "Name" = "${data.aws_region.mumbai.name}-public-subnet-${count.index + 1}"
    "Tier" = "Public"
  }
}

resource "aws_subnet" "mumbai_private_subnets" {
  provider          = aws.mumbai
  count             = length(data.aws_availability_zones.mumbai_azs.names)
  vpc_id            = aws_vpc.mumbai_vpc.id
  availability_zone = data.aws_availability_zones.mumbai_azs.names[count.index]
  cidr_block        = cidrsubnet(aws_vpc.mumbai_vpc.cidr_block, 4, count.index + 8) // to divide the /16 subnet into half/half for public and private
  tags = {
    "Name" = "${data.aws_region.mumbai.name}-private-subnet-${count.index + 1}"
    "Tier" = "Private"
  }
}

resource "aws_internet_gateway" "mumbai_igw" {
  provider = aws.mumbai
  vpc_id   = aws_vpc.mumbai_vpc.id

  tags = {
    "Name" = "${data.aws_region.mumbai.name}-igw"
  }
}

resource "aws_route_table" "mumbai_public_route_table" {
  provider = aws.mumbai
  vpc_id   = aws_vpc.mumbai_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.mumbai_igw.id
  }

  tags = {
    "Name" = "${data.aws_region.mumbai.name}-rtb-public"
  }
}

resource "aws_route_table" "mumbai_private_route_table" {
  provider = aws.mumbai
  vpc_id   = aws_vpc.mumbai_vpc.id

  tags = {
    "Name" = "${data.aws_region.mumbai.name}-rtb-private"
  }
}

resource "aws_route_table_association" "mumbai_public_subnets_associations" {
  provider       = aws.mumbai
  count          = length(aws_subnet.mumbai_public_subnets)
  subnet_id      = aws_subnet.mumbai_public_subnets[count.index].id
  route_table_id = aws_route_table.mumbai_public_route_table.id
}

resource "aws_route_table_association" "mumbai_private_subnets_associations" {
  provider       = aws.mumbai
  count          = length(aws_subnet.mumbai_private_subnets)
  subnet_id      = aws_subnet.mumbai_private_subnets[count.index].id
  route_table_id = aws_route_table.mumbai_private_route_table.id
}
