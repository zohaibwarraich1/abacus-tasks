# --- VPC Outputs ---

output "vpc_id" {
  description = "The ID of the VPC."
  value       = module.vpc_abacus.vpc_id
}

output "vpc_cidr_block" {
  description = "CIDR block of the VPC."
  value       = module.vpc_abacus.vpc_cidr_block
}

output "public_subnet_ids" {
  description = "List of IDs of public subnets."
  value       = module.vpc_abacus.public_subnet_ids
}

output "private_subnet_ids" {
  description = "List of IDs of private subnets."
  value       = module.vpc_abacus.private_subnet_ids
}

output "public_subnet_cidrs" {
  description = "List of CIDR blocks of public subnets."
  value       = module.vpc_abacus.public_subnet_cidrs
}

output "private_subnet_cidrs" {
  description = "List of CIDR blocks of private subnets."
  value       = module.vpc_abacus.private_subnet_cidrs
}

output "internet_gateway_id" {
  description = "ID of the internet gateway."
  value       = module.vpc_abacus.internet_gateway_id
}

output "regional_nat_gateway_id" {
  description = "ID of the regional NAT gateway."
  value       = module.vpc_abacus.regional_nat_gateway_id
}

output "nat_gateway_public_ips" {
  description = "Public IPs of the regional NAT gateway."
  value       = module.vpc_abacus.nat_gateway_public_ips
}

output "public_route_table_id" {
  description = "ID of the public route table."
  value       = module.vpc_abacus.public_route_table_id
}

output "private_route_table_ids" {
  description = "List of IDs of private route tables."
  value       = module.vpc_abacus.private_route_table_ids
}

output "default_security_group_id" {
  description = "ID of the default security group for the VPC."
  value       = module.vpc_abacus.default_security_group_id
}

output "default_network_acl_id" {
  description = "ID of the default network ACL."
  value       = module.vpc_abacus.default_network_acl_id
}

output "default_route_table_id" {
  description = "ID of the default route table."
  value       = module.vpc_abacus.default_route_table_id
}

output "vpc_main_route_table_id" {
  description = "ID of the main route table."
  value       = module.vpc_abacus.vpc_main_route_table_id
}

# --- Launch Template Outputs ---

output "launch_template_id" {
  description = "The ID of the launch template."
  value       = module.launch_template_abacus.launch_template_id
}

output "launch_template_arn" {
  description = "The ARN of the launch template."
  value       = module.launch_template_abacus.launch_template_arn
}

output "launch_template_name" {
  description = "The name of the launch template."
  value       = module.launch_template_abacus.launch_template_name
}

output "launch_template_latest_version" {
  description = "The latest version of the launch template."
  value       = module.launch_template_abacus.launch_template_latest_version
}

output "launch_template_default_version" {
  description = "The default version of the launch template."
  value       = module.launch_template_abacus.launch_template_default_version
}

output "iam_role_name" {
  description = "The name of the IAM role attached to the instances."
  value       = module.launch_template_abacus.iam_role_name
}

output "iam_role_arn" {
  description = "The ARN of the IAM role attached to the instances."
  value       = module.launch_template_abacus.iam_role_arn
}

output "iam_instance_profile_name" {
  description = "The name of the IAM instance profile."
  value       = module.launch_template_abacus.iam_instance_profile_name
}

output "iam_instance_profile_arn" {
  description = "The ARN of the IAM instance profile."
  value       = module.launch_template_abacus.iam_instance_profile_arn
}
