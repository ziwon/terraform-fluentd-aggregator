resource "aws_codebuild_project" "fetch_templates" {
  name          = var.app
  build_timeout = "5"
  service_role  = aws_iam_role.codebuild.arn

  artifacts {
    type                = "CODEPIPELINE"
    name                = "Fetch_Templates"
    packaging           = "NONE"
    encryption_disabled = false
  }

  cache {
    type = "NO_CACHE"
  }

  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                       = "aws/codebuild/standard:2.0"
    type                        = "LINUX_CONTAINER"
    privileged_mode             = false
    image_pull_credentials_type = "CODEBUILD"
  }

  source {
    type         = "CODEPIPELINE"
    buildspec    = data.template_file.buildspec.rendered
    insecure_ssl = false
  }
}

data "template_file" "buildspec" {
  template = "${file("${path.module}/templates/app_buildspec.yml")}"

  vars = {
    bucket_name = aws_s3_bucket.codepipeline.bucket
  }
}
