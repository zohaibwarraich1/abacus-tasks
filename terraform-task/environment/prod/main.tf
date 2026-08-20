module "vpc_abacus" {
  source                      = "../../modules/vpc"
  vpc_name                    = "project-abacus-task-vpc-test"
  enable_internet_gateway     = true
  enable_regional_nat_gateway = true
  cidr_block                  = "10.0.0.0/16"
  block_public_access         = "off"
  public_subnets = {
    "1" = {
      cidr_block = "10.0.0.0/20"
      az         = "ap-south-1a"
    }
    "2" = {
      cidr_block = "10.0.16.0/20"
      az         = "ap-south-1b"
    }
  }
  private_subnets = {
    "1" = {
      cidr_block = "10.0.128.0/20"
      az         = "ap-south-1a"
    }
    "2" = {
      cidr_block = "10.0.144.0/20"
      az         = "ap-south-1b"
    }
  }

  tags                      = var.tag
  prevent_destroy_resources = ["vpc"]
}

module "launch_template_abacus" {
  source                 = "../../modules/compute"
  launch_template_name   = "project-abacus-task-launch-template-test"
  description            = "Launch template for project abacus task"
  image_id               = "ami-0a94ba619987fb99c"
  update_default_version = true
  instance_type          = "t3.small"
  key_name               = "zohaib-aws"
  create_iam_profile     = true
  vpc_security_group_ids = [module.asg_sg.security_group_id]

  # Automatically mount the existing EFS on boot
  /**
  user_data_base64 = base64encode(<<-EOT
    #!/bin/bash
    # Update and install NFS client
    apt-get update -y
    apt-get install -y nfs-common

    # Create mount directory
    mkdir -p /var/abacus-projects

    # Mount the EFS
    mount -t nfs4 -o nfsvers=4.1,rsize=1048576,wsize=1048576,hard,timeo=600,retrans=2,noresvport fs-0f401712e86f14aab.efs.ap-south-1.amazonaws.com:/ /var/abacus-projects

    # Add to fstab so it mounts automatically after any reboot
    echo "fs-0f401712e86f14aab.efs.ap-south-1.amazonaws.com:/ /var/abacus-projects nfs4 nfsvers=4.1,rsize=1048576,wsize=1048576,hard,timeo=600,retrans=2,noresvport,_netdev 0 0" >> /etc/fstab

    # Fix permissions for apache user (optional but recommended)
    chown -R www-data:www-data /var/abacus-projects
  EOT
  )
  **/

  additional_iam_policy_arns = [
    "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryFullAccess",
    "arn:aws:iam::aws:policy/AmazonElasticFileSystemsUtils",
    "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy",
  ]
  tags = var.tag
}

module "asg-abacus" {
  source = "terraform-aws-modules/autoscaling/aws"

  # Autoscaling group
  name   = "abacus-task-asg-test-2"
  create = true

  min_size                  = 2
  max_size                  = 4
  desired_capacity          = 2
  wait_for_capacity_timeout = 0
  protect_from_scale_in     = false
  service_linked_role_arn   = "arn:aws:iam::399894608127:role/aws-service-role/autoscaling.amazonaws.com/AWSServiceRoleForAutoScaling"

  # Networking
  vpc_zone_identifier = module.vpc_abacus.private_subnet_ids
  # security_groups     = [module.asg_sg.security_group_id]

  # Attach ASG to ALB Target Group
  traffic_source_attachments = {
    alb = {
      traffic_source_identifier = module.alb.target_groups["asg-instances"].arn
      traffic_source_type       = "elbv2"
    }
  }

  # Launch template 
  create_launch_template  = false
  launch_template_id      = module.launch_template_abacus.launch_template_id
  launch_template_version = "$Latest"

  # Health checks
  health_check_type         = "ELB"
  health_check_grace_period = 300

  # Configuration
  default_instance_warmup = 300
  default_cooldown        = 300

  # Scaling Policy 
  scaling_policies = {
    target-tracking-cpu = {
      policy_type               = "TargetTrackingScaling"
      name                      = "Target Tracking Policy"
      estimated_instance_warmup = 300
      target_tracking_configuration = {
        predefined_metric_specification = {
          predefined_metric_type = "ASGAverageCPUUtilization"
        }
        target_value     = 60
        disable_scale_in = false
      }
    }
  }

  # Instance maintenance policy
  instance_maintenance_policy = {
    min_healthy_percentage = 100
    max_healthy_percentage = 110
  }

  instance_refresh = {
    strategy = "Rolling"

    preferences = {
      min_healthy_percentage = 100
      max_healthy_percentage = 110
      instance_warmup        = 300
      checkpoint_delay       = 600
      checkpoint_percentages = [20, 50, 100]
      skip_matching          = true
      auto_rollback          = true
    }
    triggers = ["tag"]
  }

  # This will ensure imdsv2 is enabled, required, and a single hop which is aws security
  # best practices
  # See https://docs.aws.amazon.com/securityhub/latest/userguide/autoscaling-controls.html#autoscaling-4
  metadata_options = {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
  }

  placement = {
    availability_zone = "us-west-1b"
  }

  tag_specifications = [
    {
      resource_type       = "instance"
      tags                = { WhatAmI = "Instance", Name = "abacus-task-asg-test-instance", purpose = "abacus-task-1-test" }
      propagate_at_launch = true
    },
    {
      resource_type       = "volume"
      tags                = { WhatAmI = "Volume", Name = "abacus-task-asg-test-volume", purpose = "abacus-task-1-test" }
      propagate_at_launch = true
    }
  ]


  tags = var.tag
}

module "alb" {
  source = "terraform-aws-modules/alb/aws"

  name                             = "abacus-alb-test"
  vpc_id                           = module.vpc_abacus.vpc_id
  subnets                          = module.vpc_abacus.public_subnet_ids
  create                           = true
  load_balancer_type               = "application"
  ip_address_type                  = "ipv4"
  enable_cross_zone_load_balancing = true
  client_keep_alive                = 3600
  enable_http2                     = true
  drop_invalid_header_fields       = true
  preserve_host_header             = false
  # delete_protection                = false
  enable_deletion_protection = false

  # Security Group
  create_security_group = false
  security_groups       = [module.alb_sg.security_group_id]

  listeners = {
    http = {
      port     = 80
      protocol = "HTTP"
      forward = {
        target_group_key = "asg-instances"
      }
      tags = var.tag
    }
  }

  target_groups = {
    asg-instances = {
      name                              = "project-abacus-task-tg-test"
      protocol                          = "HTTP"
      port                              = 80
      target_type                       = "instance"
      load_balancing_cross_zone_enabled = "use_load_balancer_configuration"
      tags                              = { purpose = "abacus-task-1-test" }
      vpc_id                            = module.vpc_abacus.vpc_id
      load_balancing_algorithm_type     = "round_robin"
      # load_balancing_anomaly_mitigation = "on"
      slow_start           = 300
      deregistration_delay = 300
      ip_address_type      = "ipv4"
      create_attachment    = false
      health_check = {
        enabled             = true
        timeout             = 10
        unhealthy_threshold = 5
        healthy_threshold   = 5
        path                = "/"
        port                = "traffic-port"
        protocol            = "HTTP"
        interval            = 30
        matcher             = "200"
      }
      target_health_state = {
        enable_unhealthy_connection_termination = true
        unhealthy_draining_interval             = 300
      }

      target_group_health = {
        dns_failover = {
          minimum_healthy_targets_count = "1"
        }
        unhealthy_state_routing = {
          minimum_healthy_targets_count = 1
        }
      }
    }
  }

  tags = var.tag
}

module "alb_sg" {
  source = "../../modules/sgs"

  name        = "abacus-alb-sg"
  description = "Security Group for the Application Load Balancer"
  vpc_id      = module.vpc_abacus.vpc_id

  ingress_rules = {
    all_http = {
      from_port   = 80
      to_port     = 80
      ip_protocol = "tcp"
      cidr_ipv4   = "0.0.0.0/0"
      description = "Allow HTTP from anywhere"
    }
    all_https = {
      from_port   = 443
      to_port     = 443
      ip_protocol = "tcp"
      cidr_ipv4   = "0.0.0.0/0"
      description = "Allow HTTPS from anywhere"
    }
  }

  egress_rules = {
    all = {
      ip_protocol = "-1"
      cidr_ipv4   = "0.0.0.0/0"
      description = "Allow all outbound traffic"
    }
  }

  tags = var.tag
}

# 2. Create the ASG/EC2 Security Group
module "asg_sg" {
  source = "../../modules/sgs"

  name        = "abacus-asg-sg"
  description = "Security Group for the ASG EC2 instances"
  vpc_id      = module.vpc_abacus.vpc_id

  ingress_rules = {
    http_from_alb = {
      from_port                    = 80
      to_port                      = 80
      ip_protocol                  = "tcp"
      referenced_security_group_id = module.alb_sg.security_group_id
      description                  = "Allow HTTP from ALB SG"
    }
    ssh_from_anywhere = {
      from_port   = 22
      to_port     = 22
      ip_protocol = "tcp"
      cidr_ipv4   = "0.0.0.0/0"
      description = "Allow SSH"
    }
  }

  egress_rules = {
    all = {
      ip_protocol = "-1"
      cidr_ipv4   = "0.0.0.0/0"
      description = "Allow all outbound traffic"
    }
  }

  tags = var.tag
}
