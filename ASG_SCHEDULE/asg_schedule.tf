################################################################################
# Autoscaling group schedule
################################################################################
resource "aws_autoscaling_schedule" "this" {
  for_each = var.create_schedule ? var.schedules : {}

  scheduled_action_name  = each.key
  autoscaling_group_name = aws_autoscaling_group.asg.name

  min_size         = try(each.value.min_size, null)
  max_size         = try(each.value.max_size, null)
  desired_capacity = try(each.value.desired_capacity, null)
  start_time       = try(each.value.start_time, null)
  end_time         = try(each.value.end_time, null)
  time_zone        = try(each.value.time_zone, null)

  # [Minute] [Hour] [Day_of_Month] [Month_of_Year] [Day_of_Week]
  # Cron examples: https://crontab.guru/examples.html
  recurrence = try(each.value.recurrence, null)
}