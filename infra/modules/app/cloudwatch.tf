resource "aws_cloudwatch_event_rule" "ecr-latest-image" {
  name          = "${var.app}-trigger-ecr"
  event_pattern = <<PATTERN
{
  "detail-type": [
    "ECR Image Action"
  ],
  "source": [
    "aws.ecr"
  ],
  "detail": {
    "action-type": [
      "PUSH"
    ],
    "image-tag": [
      "${var.pipeline_image_tag}"
    ],
    "repository-name": [
      "${var.repository_name}"
    ],
    "result": [
      "SUCCESS"
    ]
  }
}
PATTERN
  tags          = var.tags
}

resource "aws_cloudwatch_event_target" "ecr-pipeline-target" {
  rule     = aws_cloudwatch_event_rule.ecr-latest-image.name
  arn      = aws_codepipeline.main.arn
  role_arn = aws_iam_role.events.arn
}
