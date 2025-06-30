locals {
  common_name                 = "demo"
  service_name                = "web-app"
  owner                       = "ABB"
  image_id                    = data.aws_ami.image_id.id
  instance_type               = "t3a.micro"
  iam_instance_profile        = ""
  key_name                    = "Asg_test"
  security_groups             = ""
  associate_public_ip_address = true
  min_size                    = "1"
  max_size                    = "5"
  desired_capacity            = "1"
  health_check_type           = "EC2"
  instance_refresh            = "true"
  subnet_ids                  = ["subnet-517a032b", "subnet-0821ad44", "subnet-27f5c84e"]
  hostname                    = "web-app"
  vpc_id                      = "vpc-a9260dc1"
 # target_group_arns           = ""
}

data "aws_ami" "image_id" {
  most_recent = true
  owners      = ["self"]

  filter {
    name   = "name"
    values = ["CENTRAL/GOLD/AWS-LINUX-2/*"]
  }

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}
