output "launch_template_id" {
  description = "The ID of the launch template."
  value       = aws_launch_template.this.id
}

output "launch_template_arn" {
  description = "The ARN of the launch template."
  value       = aws_launch_template.this.arn
}

output "launch_template_latest_version" {
  description = "The latest version of the launch template."
  value       = aws_launch_template.this.latest_version
}

output "iam_role_name" {
  description = "The name of the IAM role attached to the instances."
  value       = try(aws_iam_role.this[0].name, null)
}

output "iam_instance_profile_name" {
  description = "The name of the IAM instance profile."
  value       = try(aws_iam_instance_profile.this[0].name, null)
}

output "iam_role_arn" {
  description = "The ARN of the IAM role attached to the instances."
  value       = try(aws_iam_role.this[0].arn, null)
}

output "iam_instance_profile_arn" {
  description = "The ARN of the IAM instance profile."
  value       = try(aws_iam_instance_profile.this[0].arn, null)
}

output "launch_template_default_version" {
  description = "The default version of the launch template."
  value       = aws_launch_template.this.default_version
}

output "launch_template_name" {
  description = "The name of the launch template."
  value       = aws_launch_template.this.name
}
