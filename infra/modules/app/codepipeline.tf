resource "aws_s3_bucket" "codepipeline" {
  bucket        = "${var.app}-codepipeline"
  acl           = "private"
  force_destroy = true
}

resource "aws_codepipeline" "main" {
  name     = "${var.app}-pipeline"
  role_arn = aws_iam_role.codepipeline.arn

  artifact_store {
    location = aws_s3_bucket.codepipeline.bucket
    type     = "S3"
  }

  stage {
    name = "Source"

    action {
      name             = "Source"
      category         = "Source"
      owner            = "AWS"
      provider         = "ECR"
      version          = "1"
      output_artifacts = ["source"]

      configuration = {
        ImageTag       = "latest"
        RepositoryName = "fluentd-aggregator"
      }
    }
  }

  stage {
    name = "Fetch"

    action {
      name             = "Fetch"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      input_artifacts  = ["source"]
      output_artifacts = ["fetch"]
      version          = "1"

      configuration = {
        ProjectName = var.app
      }
    }
  }

  stage {
    name = "Deploy"

    action {
      name            = "Deploy"
      category        = "Deploy"
      owner           = "AWS"
      provider        = "CodeDeployToECS"
      version         = "1"
      input_artifacts = ["source", "fetch"]

      configuration = {
        ApplicationName                = aws_codedeploy_app.main.name
        DeploymentGroupName            = aws_codedeploy_deployment_group.main.deployment_group_name
        AppSpecTemplateArtifact        = "fetch"
        AppSpecTemplatePath            = "appspec.yml"
        TaskDefinitionTemplateArtifact = "fetch"
        TaskDefinitionTemplatePath     = "taskdef.json"
        Image1ArtifactName             = "source"
        Image1ContainerName            = "IMAGE1"
      }
    }
  }

  depends_on = [
    null_resource.get_taskdef
  ]
}

resource "null_resource" "get_taskdef" {
  triggers = {
    always_run = "${timestamp()}"
  }

  provisioner "local-exec" {
    command = "bash ${path.module}/upload-meta.sh ${aws_ecs_task_definition.main.family} ${aws_s3_bucket.codepipeline.bucket} ${var.task_definition.cpu} ${var.task_definition.memory} ${aws_iam_role.app_role.arn} ${aws_iam_role.ecsTaskExecutionRole.arn}"
  }

  depends_on = [
    aws_ecs_service.main,
    aws_ecs_task_definition.main
  ]
}
