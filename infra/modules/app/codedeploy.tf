resource "aws_codedeploy_app" "main" {
  compute_platform = "ECS"
  name             = var.app

  depends_on = [aws_ecs_service.main]
}

resource "aws_codedeploy_deployment_group" "main" {
  app_name = aws_codedeploy_app.main.name

  # For ECS deployment group, autoScalingGroups can not be specified
  # autoscaling_groups     = [aws_appautoscaling_target.app_scale_target.id]
  deployment_config_name = "CodeDeployDefault.ECSAllAtOnce"
  deployment_group_name  = "${var.app}-deployment"
  service_role_arn       = aws_iam_role.codedeploy.arn

  auto_rollback_configuration {
    enabled = true
    events  = ["DEPLOYMENT_FAILURE"]
  }

  blue_green_deployment_config {
    deployment_ready_option {
      action_on_timeout = "CONTINUE_DEPLOYMENT"
    }

    terminate_blue_instances_on_deployment_success {
      action                           = "TERMINATE"
      termination_wait_time_in_minutes = 3
    }
  }

  deployment_style {
    deployment_option = "WITH_TRAFFIC_CONTROL"
    deployment_type   = "BLUE_GREEN"
  }

  ecs_service {
    cluster_name = aws_ecs_cluster.main.name
    service_name = aws_ecs_service.main.name
  }

  load_balancer_info {
    target_group_pair_info {
      prod_traffic_route {
        listener_arns = [aws_lb_listener.tcp.arn]
      }

      target_group {
        name = aws_lb_target_group.blue.name
      }

      target_group {
        name = aws_lb_target_group.green.name
      }
    }
  }

  depends_on = [
    aws_lb_target_group.blue,
    aws_lb_target_group.green,
    aws_ecs_service.main
  ]
}
