variable "vpc_name" {
  description = "The name of the VPC. This will be used to create a Name tag for the VPC and its associated resources."

  type = string

  validation {
    condition     = length(trimspace(var.vpc_name)) > 0
    error_message = "The value of vpc_name must not be empty."
  }
}

variable "cidr_block" {
  description = "The CIDR block for the VPC. Must be a valid CIDR range."

  type = string

  validation {
    condition     = can(cidrnetmask(var.cidr_block))
    error_message = "The value of cidr_block must be a valid CIDR block, for example 10.0.0.0/16."
  }
}

variable "tags" {
  description = "A map of tags to add additional metadata to the VPC and its associated resources."

  type    = map(string)
  default = {}
}

variable "instance_tenancy" {
  description = "The instance tenancy option for the VPC. Valid values are 'default' and 'dedicated'."

  type    = string
  default = "default"

  validation {
    condition     = contains(["default", "dedicated"], var.instance_tenancy)
    error_message = "The value of instance_tenancy must be either 'default' or 'dedicated'."
  }
}

variable "enable_dns_support" {
  description = "Enable DNS support for the VPC. If true, instances in the VPC can resolve public DNS hostnames to IP addresses. If false, they cannot."

  type    = bool
  default = true
}

variable "enable_dns_hostnames" {
  description = "Enable DNS hostnames for the VPC. If true, instances in the VPC get DNS hostnames. Otherwise, they will not. This is required for instances to be reachable by their public DNS names."

  type    = bool
  default = true
}

variable "block_public_access" {
  description = "Block public access to the VPC. It is used to control access to the VPC."
  
  type        = string
  default    = "off"

  validation {
    condition     = contains(["block-bidirectional", "block-ingress", "off"], var.block_public_access)
    error_message = "The value of block_public_access must be either 'block-bidirectional', 'block-ingress', 'off'."
  }
}

variable "enable_internet_gateway" {
  description = "Enable the internet gateway for the VPC."
  type        = bool
  # default = null

  validation {
    condition     = var.enable_internet_gateway == false || var.enable_internet_gateway == true
    error_message = "enable_internet_gateway can only be true or false."
  }
}

variable "enable_regional_nat_gateway" {
  description = "Enable the regional NAT gateway for the VPC."
  type        = bool
  # default     = null

  validation {
    condition     = var.enable_regional_nat_gateway == false || (var.enable_regional_nat_gateway == true && var.enable_internet_gateway == true)
    error_message = "enable_regional_nat_gateway can only be true when enable_internet_gateway is also true."
  }
}

variable "public_subnets" {
  description = "A map of public subnets to create in the VPC. Each subnet is defined by its CIDR block and availability zone."

  type = map(object({
    cidr_block                          = string
    az                                  = string
    enable_dns_a_record_on_launch       = optional(bool, true)
    enable_dns_aaaa_record_on_launch    = optional(bool, false)
    private_dns_hostname_type_on_launch = optional(string, "ip-name")
    map_public_ip_on_launch             = optional(bool, true)
  }))
  default = {}
}

# variable "public_route_table_routes" {
#   description = "Routes to add to the public route table. Each entry can target an internet gateway, NAT gateway, local route, or another supported target."

#   type = list(object({
#     cidr_block  = string
#     target_type = optional(string, "igw")
#     target_id   = optional(string, null)
#   }))
#   default = []

#   validation {
#     condition = alltrue([
#       for route in var.public_route_table_routes : contains(["igw", "nat", "local", "instance", "vpc_peering", "transit_gateway", "egress_only_gateway", "carrier_gateway"], route.target_type)
#     ])
#     error_message = "Each route target_type must be one of: igw, nat, local, instance, vpc_peering, transit_gateway, egress_only_gateway, carrier_gateway."
#   }
# }

variable "private_subnets" {
  description = "A map of private subnets to create in the VPC. Each subnet is defined by its CIDR block and availability zone."

  type = map(object({
    cidr_block                          = string
    az                                  = string
    enable_dns_a_record_on_launch       = optional(bool, true)
    enable_dns_aaaa_record_on_launch    = optional(bool, false)
    private_dns_hostname_type_on_launch = optional(string, "ip-name")
    map_public_ip_on_launch             = optional(bool, false)
  }))
  default = {}
}

variable prevent_destroy_resources {
  description = "A list of resource types to prevent from being destroyed. This can be used to protect critical resources from accidental deletion."

  type    = list(string)
  default = []
}