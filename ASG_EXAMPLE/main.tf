module "asg" {
  source                    = "../ASG_SCHEDULE/"
  common_name               = local.common_name
  service_name              = local.service_name
  environment               = terraform.workspace
  instance_type             = local.instance_type
  image_id                  = local.image_id
  key_name                  = local.key_name
  min_size                  = local.min_size
  max_size                  = local.max_size
  subnet_ids                = local.subnet_ids
  desired_capacity          = local.desired_capacity
  health_check_type         = local.health_check_type
  instance_refresh          = local.instance_refresh
  user_data_base64          = base64encode(data.template_file.init.rendered)
  iam_instance_profile_name = aws_iam_instance_profile.instance_profile.name
  vpc_id                    = ""
  security_groups           = [aws_security_group.this.id]
  common_tags = {
    Service = local.service_name
    Owner   = local.owner
  }
  # Autoscaling Schedule
  create_schedule = true

  schedules = {
    night = {
      min_size         = 0
      max_size         = 0
      desired_capacity = 0
      recurrence       = "0 20 * * 1-5" # Mon-Fri in the evening
      time_zone        = "Europe/London"
    }
    morning = {
      min_size         = 1
      max_size         = 5
      desired_capacity = 1
      recurrence       = "0 7 * * 1-5" # Mon-Fri in the morning
      time_zone        = "Europe/London"
    }

    go-offline-to-celebrate-new-year = {
      min_size         = 0
      max_size         = 0
      desired_capacity = 0
      start_time       = "2022-12-31T10:00:00Z" # Should be in the future
      end_time         = "2032-01-01T16:00:00Z"
      time_zone        = "Europe/London"
    }
  }
}

