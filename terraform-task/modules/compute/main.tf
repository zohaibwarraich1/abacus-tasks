locals {
  default_iam_instance_profile = var.create_iam_profile ? {
    name = aws_iam_instance_profile.this[0].name
  } : null

  iam_instance_profile = var.iam_instance_profile == null ? local.default_iam_instance_profile : var.iam_instance_profile
}

resource "aws_launch_template" "this" {
  name        = var.launch_template_name
  description = var.description

  update_default_version = var.update_default_version

  image_id      = var.image_id
  instance_type = var.instance_type
  key_name      = var.key_name

  vpc_security_group_ids = var.vpc_security_group_ids

  user_data = var.user_data_base64

  dynamic "iam_instance_profile" {
    for_each = local.iam_instance_profile == null ? [] : [local.iam_instance_profile]
    content {
      name = try(iam_instance_profile.value.name, null)
      arn  = try(iam_instance_profile.value.arn, null)
    }
  }

  dynamic "block_device_mappings" {
    for_each = var.block_device_mappings
    content {
      device_name = block_device_mappings.value.device_name

      ebs {
        volume_size           = block_device_mappings.value.volume_size
        volume_type           = block_device_mappings.value.volume_type
        delete_on_termination = block_device_mappings.value.delete_on_termination
        encrypted             = block_device_mappings.value.encrypted
      }
    }
  }

  tag_specifications {
    resource_type = "instance"
    tags          = merge(var.tags, { Name = var.launch_template_name })
  }

  tag_specifications {
    resource_type = "volume"
    tags          = merge(var.tags, { Name = var.launch_template_name })
  }

  tags = var.tags
}
