output "vpc_id" {
  description = "ID of the created VPC."
  value       = aws_vpc.main.id
}

output "public_subnet_ids" {
  description = "IDs of the created public subnets."
  value       = [for subnet in values(aws_subnet.public_subnets) : subnet.id]
}

output "private_subnet_ids" {
  description = "IDs of the created private subnets."
  value       = [for subnet in values(aws_subnet.private_subnets) : subnet.id]
}

output "internet_gateway_id" {
  description = "ID of the internet gateway when enabled."
  value       = try(aws_internet_gateway.igw[0].id, null)
}

output "regional_nat_gateway_id" {
  description = "ID of the regional NAT gateway when enabled."
  value       = try(aws_nat_gateway.regional_nat[0].id, null)
}

output "vpc_cidr_block" {
  description = "CIDR block of the created VPC."
  value       = aws_vpc.main.cidr_block
}

output "public_subnet_cidrs" {
  description = "CIDR blocks of the created public subnets."
  value       = [for subnet in values(aws_subnet.public_subnets) : subnet.cidr_block]
}

output "private_subnet_cidrs" {
  description = "CIDR blocks of the created private subnets."
  value       = [for subnet in values(aws_subnet.private_subnets) : subnet.cidr_block]
}

output "public_route_table_id" {
  description = "ID of the public route table associated with the VPC."
  value       = aws_route_table.public_subnet_rt.id
}

output "private_route_table_ids" {
  description = "IDs of the private route tables created for the private subnets."
  value       = [for route_table in values(aws_route_table.private_subnet_rts) : route_table.id]
}

output "default_security_group_id" {
  description = "The ID of the security group created by default on VPC creation."
  value       = aws_vpc.main.default_security_group_id
}

output "default_network_acl_id" {
  description = "The ID of the network ACL created by default on VPC creation."
  value       = aws_vpc.main.default_network_acl_id
}

output "default_route_table_id" {
  description = "The ID of the route table created by default on VPC creation."
  value       = aws_vpc.main.default_route_table_id
}

output "vpc_main_route_table_id" {
  description = "The ID of the main route table associated with this VPC."
  value       = aws_vpc.main.main_route_table_id
}

output "nat_gateway_public_ips" {
  description = "Public IPs of the regional NAT gateway when enabled."
  value       = try(aws_nat_gateway.regional_nat[*].public_ip, [])
}

output "private_subnets_azs" {
  description = "Availability Zones of the created private subnets."
  value       = [for subnet in values(aws_subnet.private_subnets) : subnet.availability_zone]
}

output "public_subnets_azs" {
  description = "Availability Zones of the created public subnets."
  value       = [for subnet in values(aws_subnet.public_subnets) : subnet.availability_zone]
}