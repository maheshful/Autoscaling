resource "aws_security_group" "this" {
  vpc_id = local.vpc_id

  name_prefix = upper(format("%s-%s-s%-sg", local.common_name, local.service_name, terraform.workspace))

  description = upper(format("%s-%s-%s of EC2", local.common_name, local.service_name, terraform.workspace))

  tags = {
    Name = upper(format("%s-%s-s%-sg", local.common_name, local.service_name, terraform.workspace))
  }

  lifecycle {
    create_before_destroy = true

    ignore_changes = [
      tags["CreatedActor"]
    ]
  }
}