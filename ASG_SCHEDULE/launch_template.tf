resource "aws_launch_template" "default" {

  name_prefix   = upper(join("/", [local.name, "launch/template"]))
  image_id      = var.image_id
  instance_type = var.instance_type
  user_data     = var.user_data_base64
  ebs_optimized = var.ebs_optimized
  
  dynamic "iam_instance_profile" {
    for_each = var.iam_instance_profile_name != "" ? [var.iam_instance_profile_name] : []
    content {
      name = iam_instance_profile.value
    }
  }

  network_interfaces {
    description                 = upper(join("/", [local.name, "SG"]))
    device_index                = 0
    associate_public_ip_address = var.associate_public_ip_address
    delete_on_termination       = true
    security_groups             = var.security_groups
  }

  monitoring {
    enabled = var.enable_monitoring
  }

  tags = var.common_tags

  lifecycle {
    create_before_destroy = true
  }
}
