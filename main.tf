# provider "aws" {
#   region     = "var.Region"
#   access_key = "var.my-access-key"
#   secret_key = "var.my-secret-key"
# }
# resource "aws_vpc" "this" {
#   count = var.create_vpc ? 1 : 0

#   cidr_block                       = var.cidr
#   instance_tenancy                 = var.instance_tenancy
#   enable_dns_hostnames             = var.enable_dns_hostnames
#   enable_dns_support               = var.enable_dns_support
#   enable_classiclink               = var.enable_classiclink
#   enable_classiclink_dns_support   = var.enable_classiclink_dns_support
#   assign_generated_ipv6_cidr_block = var.enable_ipv6

#   tags = merge(
#     {
#       "Name" = format("%s", var.name)
#     },
#     var.tags,
#     var.vpc_tags,
#   )
# }
provider "aws" {
      region     = "${var.region}"
      access_key = "${var.access_key}"
      secret_key = "${var.secret_key}"
}
terraform {
  backend "s3" {
    bucket = "my-usage-store"
    key    = "test-terraform-state/terraform.tfstate"
    region = "us-east-1"
  }
}


# VPC resources: This will create 1 VPC with 4 Subnets, 1 Internet Gateway, 4 Route Tables. 

resource "aws_vpc" "my_vpc" {
  cidr_block           = var.cidr_block
  enable_dns_support   = true
  enable_dns_hostnames = true
}

resource "aws_internet_gateway" "my_igw" {
  vpc_id = aws_vpc.my_vpc.id
}

# resource "aws_route_table" "private" {
#   count = length(var.private_subnet_cidr_blocks)

#   vpc_id = aws_vpc.my_vpc.id
# }

# resource "aws_route" "private" {
#   count = length(var.private_subnet_cidr_blocks)

#   route_table_id         = aws_route_table.private[count.index].id
#   destination_cidr_block = "0.0.0.0/0"
#   nat_gateway_id         = aws_nat_gateway.my_nat[count.index].id
# }

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.my_vpc.id
}

resource "aws_route" "public" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.my_igw.id
}

# resource "aws_subnet" "private" {
#   count = length(var.private_subnet_cidr_blocks)

#   vpc_id            = aws_vpc.my_vpc.id
#   cidr_block        = var.private_subnet_cidr_blocks[count.index]
#   availability_zone = var.availability_zones[count.index]
# }

resource "aws_subnet" "public" {
  count = length(var.public_subnet_cidr_blocks)

  vpc_id                  = aws_vpc.my_vpc.id
  cidr_block              = var.public_subnet_cidr_blocks[count.index]
  availability_zone       = var.availability_zones[count.index]
  map_public_ip_on_launch = true
}

# resource "aws_route_table_association" "private" {
#   count = length(var.private_subnet_cidr_blocks)

#   subnet_id      = aws_subnet.private[count.index].id
#   route_table_id = aws_route_table.private[count.index].id
# }

resource "aws_route_table_association" "public" {
  count = length(var.public_subnet_cidr_blocks)

  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}


# NAT resources: This will create 2 NAT gateways in 2 Public Subnets for 2 different Private Subnets.

# resource "aws_eip" "nat" {
#   count = length(var.public_subnet_cidr_blocks)

#   vpc = true
# }

# resource "aws_nat_gateway" "my_nat" {
#   depends_on = ["aws_internet_gateway.my_igw"]

#   count = length(var.public_subnet_cidr_blocks)

#   allocation_id = aws_eip.nat[count.index].id
#   subnet_id     = aws_subnet.public[count.index].id
# }