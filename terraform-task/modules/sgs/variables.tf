variable "name" {
  description = "Name of the security group"
  type        = string
}

variable "description" {
  description = "Description of the security group"
  type        = string
  default     = "Security Group managed by Terraform"
}

variable "vpc_id" {
  description = "ID of the VPC where to create security group"
  type        = string
}

variable "tags" {
  description = "A map of tags to add to all resources"
  type        = map(string)
  default     = {}
}

variable "ingress_rules" {
  description = "Map of ingress rules to create"
  type = map(object({
    description                  = optional(string, "Managed by Terraform")
    from_port                    = optional(number)
    to_port                      = optional(number)
    ip_protocol                  = string
    cidr_ipv4                    = optional(string)
    cidr_ipv6                    = optional(string)
    prefix_list_id               = optional(string)
    referenced_security_group_id = optional(string)
  }))
  default = {}
}

variable "egress_rules" {
  description = "Map of egress rules to create"
  type = map(object({
    description                  = optional(string, "Managed by Terraform")
    from_port                    = optional(number)
    to_port                      = optional(number)
    ip_protocol                  = string
    cidr_ipv4                    = optional(string)
    cidr_ipv6                    = optional(string)
    prefix_list_id               = optional(string)
    referenced_security_group_id = optional(string)
  }))
  default = {}
}
