terraform {
  backend "s3" {
    key            = "asg/asg.tfstate"
    region         = "ap-south-1"
    bucket         = "asg-tfstate"
  }
}
