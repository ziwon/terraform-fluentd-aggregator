data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

data "aws_subnet_ids" "private" {
  vpc_id = var.vpc_id

  tags = {
    Type = "private"
  }
}

data "aws_subnet_ids" "public" {
  vpc_id = var.vpc_id

  tags = {
    Type = "public"
  }
}


