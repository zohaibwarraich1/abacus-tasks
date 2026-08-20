variable "launch_template_name" {
  description = "Optional name of the launch template. Conflicts with name_prefix."
  type        = string

  validation {
    condition     = length(var.launch_template_name) > 0
    error_message = "launch_template_name must be set."
  }
}

variable "description" {
  description = "Description of the launch template."
  type        = string

  validation {
    condition     = length(var.description) > 0
    error_message = "Description of Launch Template ${var.launch_template_name} must be provided."
  }
}

variable "update_default_version" {
  description = "Whether to update the default version of the launch template automatically."
  type        = bool
  default     = true
}

variable "image_id" {
  description = "The AMI from which to launch the instance."
  type        = string

  validation {
    condition     = length(var.image_id) > 0
    error_message = "Image ID musted be set in launch template ${var.launch_template_name}"
  }
}

variable "instance_type" {
  description = "The type of the instance."
  type        = string
  default     = null
}

variable "key_name" {
  description = "The key name to use for the instance."
  type        = string
  default     = null
}

variable "vpc_security_group_ids" {
  description = "A list of security group IDs to associate with."
  type        = list(string)
  default     = []
}

variable "user_data_base64" {
  description = "The Base64-encoded user data to provide when launching the instance."
  type        = string
  default     = null
}

variable "tags" {
  description = "A map of tags to assign to the resource."
  type        = map(string)
  default     = {}
}

variable "block_device_mappings" {
  description = "Simple block device mapping configuration."
  type = list(object({
    device_name           = string
    volume_size           = number
    volume_type           = optional(string, "gp3")
    delete_on_termination = optional(bool, true)
    encrypted             = optional(bool, true)
  }))
  default = []
}

# --- IAM Variables ---

variable "create_iam_profile" {
  description = "Whether to create the IAM role and instance profile for the launch template internally."
  type        = bool
  default     = true
}

variable "iam_instance_profile" {
  description = "External IAM instance profile to attach if create_iam_profile is false."
  type = object({
    name = optional(string)
    arn  = optional(string)
  })
  default = null
}

variable "additional_iam_policy_arns" {
  description = "A list of additional IAM policy ARNs to attach to the automatically created instance profile role."
  type        = list(string)
  default     = []
}
