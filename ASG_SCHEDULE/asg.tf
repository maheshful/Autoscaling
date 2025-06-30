resource "aws_autoscaling_group" "asg" {
  depends_on                = [aws_launch_template.default]
  name                      = upper(format("%s_ASG", local.name))
  max_size                  = var.max_size
  min_size                  = var.min_size
  health_check_grace_period = var.health_check_grace_period
  health_check_type         = var.health_check_type
  desired_capacity          = var.desired_capacity
  force_delete              = var.force_delete
  load_balancers            = var.load_balancers
  vpc_zone_identifier       = var.subnet_ids
  target_group_arns         = var.target_group_arns
  termination_policies      = var.termination_policies
  suspended_processes       = var.suspended_processes
  placement_group           = var.placement_group
  metrics_granularity       = var.metrics_granularity
  enabled_metrics           = var.enabled_metrics
  wait_for_capacity_timeout = var.wait_for_capacity_timeout
  min_elb_capacity          = var.min_elb_capacity
  wait_for_elb_capacity     = var.wait_for_elb_capacity
  protect_from_scale_in     = var.protect_from_scale_in
  service_linked_role_arn   = var.service_linked_role_arn
  launch_template {
    id      = aws_launch_template.default.id
    version = aws_launch_template.default.latest_version
  }
  instance_refresh {
    strategy = "Rolling"
    preferences {
      min_healthy_percentage = 50
    }
  }
  tag { 
      key                 = "Name"
      value               = upper(format("%s_ASG", local.name))
      propagate_at_launch = true
  }
}
