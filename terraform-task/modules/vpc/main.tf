resource "aws_vpc" "main" {
  cidr_block           = var.cidr_block
  instance_tenancy     = var.instance_tenancy
  enable_dns_support   = var.enable_dns_support
  enable_dns_hostnames = var.enable_dns_hostnames
  tags = merge(
    var.tags,
    {
      Name = "${var.vpc_name}-vpc"
    }
  )
}

resource "aws_vpc_block_public_access_options" "vpc_block_public_access" {
  count = var.block_public_access == "off" ? 0 : 1

  internet_gateway_block_mode = var.block_public_access
}

resource "aws_internet_gateway" "igw" {
  count = var.enable_internet_gateway == true ? 1 : 0

  vpc_id = aws_vpc.main.id

  tags = merge(
    var.tags,
    {
      Name = "${var.vpc_name}-igw"
    }
  )
}

resource "aws_subnet" "public_subnets" {
  for_each = var.public_subnets

  vpc_id                                      = aws_vpc.main.id
  cidr_block                                  = each.value.cidr_block
  availability_zone                           = each.value.az
  enable_resource_name_dns_a_record_on_launch = each.value.enable_dns_a_record_on_launch

  enable_resource_name_dns_aaaa_record_on_launch = each.value.enable_dns_aaaa_record_on_launch

  private_dns_hostname_type_on_launch = each.value.private_dns_hostname_type_on_launch

  map_public_ip_on_launch = each.value.map_public_ip_on_launch
  tags                    = merge(var.tags, { Name = "${var.vpc_name}-subnet-public-${index(keys(var.public_subnets), each.key) + 1}-${each.value.az}" })
}

resource "aws_subnet" "private_subnets" {
  for_each = var.private_subnets

  vpc_id                                      = aws_vpc.main.id
  cidr_block                                  = each.value.cidr_block
  availability_zone                           = each.value.az
  enable_resource_name_dns_a_record_on_launch = each.value.enable_dns_a_record_on_launch

  enable_resource_name_dns_aaaa_record_on_launch = each.value.enable_dns_aaaa_record_on_launch

  private_dns_hostname_type_on_launch = each.value.private_dns_hostname_type_on_launch

  map_public_ip_on_launch = each.value.map_public_ip_on_launch
  tags                    = merge(var.tags, { Name = "${var.vpc_name}-subnet-private-${index(keys(var.private_subnets), each.key) + 1}-${each.value.az}" })
}

/* 
Below is the Regional gateway with auto-mode enabled. It will automatically create a NAT gateway in each AZ where there is a public subnet. This is useful for high availability and fault tolerance. 

Note: There is only 1 regional nat gateway per VPC. The Regional NAT gateway is only created if enable_regional_nat_gateway is set to true and enable_internet_gateway is also set to true. If enable_internet_gateway is false, the Regional NAT gateway will not be created even if enable_regional_nat_gateway is true.
*/

resource "aws_nat_gateway" "regional_nat" {
  count = var.enable_regional_nat_gateway == true ? 1 : 0

  vpc_id            = aws_vpc.main.id
  availability_mode = "regional"
  connectivity_type = "public"

  tags = merge(
    var.tags,
    {
      Name = "${var.vpc_name}-regional-nat"
    }
  )

  # To ensure proper ordering, it is recommended to add an explicit dependency
  # on the Internet Gateway for the VPC.
  depends_on = [aws_internet_gateway.igw]
}

/* regional NAT dedicated route table removed; private route tables will receive explicit aws_route resources pointing to the regional NAT when enabled */

resource "aws_route_table" "public_subnet_rt" {
  vpc_id = aws_vpc.main.id


  tags = merge(
    var.tags,
    {
      Name = "${var.vpc_name}-rtb-public"
    }
  )
}

resource "aws_route" "public_default" {
  count                  = var.enable_internet_gateway ? 1 : 0
  route_table_id         = aws_route_table.public_subnet_rt.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = try(aws_internet_gateway.igw[0].id, null)
  depends_on             = [aws_internet_gateway.igw]
}

resource "aws_main_route_table_association" "public_subnet_mainRT_association" {
  vpc_id         = aws_vpc.main.id
  route_table_id = aws_route_table.public_subnet_rt.id
  depends_on     = [aws_vpc.main]
}

resource "aws_route_table_association" "public_subnet_rt_associations" {
  for_each = aws_subnet.public_subnets

  subnet_id      = each.value.id
  route_table_id = aws_route_table.public_subnet_rt.id
}

resource "aws_route_table" "private_subnet_rts" {
  for_each = aws_subnet.private_subnets
  vpc_id   = aws_vpc.main.id



  tags = merge(
    var.tags,
    {
      Name = "${var.vpc_name}-rtb-private-${index(keys(var.private_subnets), each.key) + 1}-${each.value.availability_zone}"
    }
  )
}

resource "aws_route_table_association" "private_subnet_rt_associations" {
  for_each = aws_subnet.private_subnets

  subnet_id      = each.value.id
  route_table_id = aws_route_table.private_subnet_rts[each.key].id
}

resource "aws_route" "private_default" {
  for_each               = var.enable_regional_nat_gateway ? aws_subnet.private_subnets : {}
  route_table_id         = aws_route_table.private_subnet_rts[each.key].id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = try(aws_nat_gateway.regional_nat[0].id, null)
  depends_on             = [aws_nat_gateway.regional_nat]
}
