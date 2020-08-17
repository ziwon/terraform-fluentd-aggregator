resource "aws_sns_topic" "codepipeline" {
  name                                     = "CodeStarNotifications-${var.app}"
  display_name                             = "Reserved for notifications from AWS Chatbot to Slack"
  application_success_feedback_sample_rate = 0
  http_success_feedback_sample_rate        = 0
  lambda_success_feedback_sample_rate      = 0
}

data "aws_iam_policy_document" "notification" {
  statement {
    actions = ["sns:Publish"]

    principals {
      type        = "Service"
      identifiers = ["codestar-notifications.amazonaws.com"]
    }

    resources = [aws_sns_topic.codepipeline.arn]
  }
}

resource "aws_sns_topic_policy" "noti-access" {
  arn    = aws_sns_topic.codepipeline.arn
  policy = data.aws_iam_policy_document.notification.json
}

resource "aws_codestarnotifications_notification_rule" "deloy" {
  detail_type = "FULL"
  event_type_ids = [
    "codepipeline-pipeline-action-execution-failed",
    "codepipeline-pipeline-action-execution-succeeded",
    "codepipeline-pipeline-pipeline-execution-failed",
    "codepipeline-pipeline-manual-approval-failed",
    "codepipeline-pipeline-manual-approval-succeeded"
  ]

  name     = "deploy-${var.app}"
  resource = aws_codepipeline.main.arn

  # The terraform not support AWS Chatbot (Beta)
  target {
    address = "arn:aws:chatbot::57xxxxxxxxxx:chat-configuration/slack-channel/your-slack-noti"
    type    = "AWSChatbotSlack"
  }

  tags = var.tags
}
