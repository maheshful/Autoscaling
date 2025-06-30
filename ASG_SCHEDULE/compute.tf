locals {
  name = upper(format("%s/%s/%s", var.common_name, var.service_name, var.environment))
  tags = var.common_tags
}