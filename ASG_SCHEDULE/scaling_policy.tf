#------------------------------------------------------------------------------
# AUTOSCALING POLICIES
#------------------------------------------------------------------------------
# Scaling UP - CPU High
resource "aws_autoscaling_policy" "cpu_high" {
  name                   = upper(format("%s-cpu-high", local.name))
  autoscaling_group_name = aws_autoscaling_group.asg.name
  adjustment_type        = "ChangeInCapacity"
  policy_type            = "SimpleScaling"
  scaling_adjustment     = "1"
  cooldown               = "300"
}
# Scaling DOWN - CPU Low
resource "aws_autoscaling_policy" "cpu_low" {
  name                   = upper(format("%s-cpu-low", local.name))
  autoscaling_group_name = aws_autoscaling_group.asg.name
  adjustment_type        = "ChangeInCapacity"
  policy_type            = "SimpleScaling"
  scaling_adjustment     = "-1"
  cooldown               = "300"
}

#------------------------------------------------------------------------------
# CLOUDWATCH METRIC ALARMS
#------------------------------------------------------------------------------
resource "aws_cloudwatch_metric_alarm" "cpu_high_alarm" {
  alarm_name          = upper(format("%s-cpu-high-alarm", local.name))
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "60"
  statistic           = "Average"
  threshold           = "80"
  actions_enabled     = true
  alarm_actions       = ["${aws_autoscaling_policy.cpu_high.arn}"]
  dimensions = {
    "AutoScalingGroupName" = "${aws_autoscaling_group.asg.name}"
  }
}
resource "aws_cloudwatch_metric_alarm" "cpu_low_alarm" {
  alarm_name          = upper(format("%s-cpu-low-alarm", local.name))
  comparison_operator = "LessThanOrEqualToThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "60"
  statistic           = "Average"
  threshold           = "10"
  actions_enabled     = true
  alarm_actions       = ["${aws_autoscaling_policy.cpu_low.arn}"]
  dimensions = {
    "AutoScalingGroupName" = "${aws_autoscaling_group.asg.name}"
  }
}