resource "aws_iam_instance_profile" "instance_profile" {
  name =  upper(format("%s-%s-%s-instance-profile", local.common_name, local.service_name, terraform.workspace))
  role = aws_iam_role.this.name
}

resource "aws_iam_role" "this" {
  name = upper(format("%s-%s-%s-instance-role", local.common_name, local.service_name, terraform.workspace))
  path = "/"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      },
    ]
  })
}


resource "aws_iam_role_policy" "ebs_volume_policy" {
  name = upper(format("%s-%s-%s-ebs-volume", local.common_name, local.service_name, terraform.workspace))
  role = aws_iam_role.this.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
        {
            Effect = "Allow",
            Action = [
                "ec2:Describe*",
                "ec2:AttachVolume",
                "ec2:DetachVolume",
                "ssm:StartSession",
                "ssm:TerminateSession",
                "ssm:ResumeSession",
                "ssm:DescribeSessions",
                "ssm:GetConnectionStatus"
            ]
            Resource = [ "*",
                "arn:aws:ec2:*:*:volume/*",
                "arn:aws:ec2:*:*:instance/*"
                ]
        },
    ]
})
}