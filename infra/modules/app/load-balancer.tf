resource "aws_lb" "main" {
  name = var.app

  load_balancer_type = "network"

  # launch lbs in public or private subnets based on "internal" variable
  internal = var.internal_load_balancer
  subnets  = split(",", var.internal_load_balancer ? join(",", data.aws_subnet_ids.private.ids) : join(",", data.aws_subnet_ids.public.ids))
  #security_groups = [aws_security_group.lb.id]
  tags = var.tags

  # enable access logs in order to get support from aws
  access_logs {
    enabled = true
    bucket  = aws_s3_bucket.lb_access_logs.bucket
  }
}

resource "aws_lb_target_group" "blue" {
  name                 = "${var.app}-blue"
  port                 = 24224
  protocol             = "TCP"
  vpc_id               = var.vpc_id
  target_type          = "ip"
  deregistration_delay = 30

  health_check {
    port                = 24224
    protocol            = "TCP"
    interval            = 30
    healthy_threshold   = 3
    unhealthy_threshold = 3
  }

  tags = var.tags
}

resource "aws_lb_target_group" "green" {
  name                 = "${var.app}-green"
  port                 = 24224
  protocol             = "TCP"
  vpc_id               = var.vpc_id
  target_type          = "ip"
  deregistration_delay = 30

  health_check {
    port                = 24224
    protocol            = "TCP"
    interval            = 30
    healthy_threshold   = 3
    unhealthy_threshold = 3
  }

  tags = var.tags
}

# bucket for storing ALB access logs
resource "aws_s3_bucket" "lb_access_logs" {
  bucket        = "${var.app}-lb-access-logs"
  acl           = "private"
  tags          = var.tags
  force_destroy = true

  lifecycle_rule {
    id                                     = "cleanup"
    enabled                                = true
    abort_incomplete_multipart_upload_days = 1
    prefix                                 = ""

    expiration {
      days = var.lb_access_logs_expiration_days
    }
  }

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }
}

# give load balancing service access to the bucket
resource "aws_s3_bucket_policy" "lb_access_logs" {
  bucket = aws_s3_bucket.lb_access_logs.id

  policy = <<POLICY
{
  "Id": "Policy",
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "s3:PutObject"
      ],
      "Effect": "Allow",
      "Resource": [
        "${aws_s3_bucket.lb_access_logs.arn}",
        "${aws_s3_bucket.lb_access_logs.arn}/*"
      ],
      "Principal": "*"
    }
  ]
}
POLICY
}

#################################################################################
# TCP Listener
#################################################################################
resource "aws_lb_listener" "tcp" {
  load_balancer_arn = aws_lb.main.id
  port              = 24224
  protocol          = "TCP"

  default_action {
    target_group_arn = aws_lb_target_group.blue.id
    type             = "forward"
  }
}

resource "aws_security_group_rule" "ingress_lb_tcp" {
  type        = "ingress"
  from_port   = 24224
  to_port     = 24224
  protocol    = "TCP"
  cidr_blocks = ["0.0.0.0/0"]

  security_group_id = aws_security_group.lb.id
}
