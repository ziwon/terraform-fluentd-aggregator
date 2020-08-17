module "global" {
  source = "./modules/global"
  name   = local.app_id
}


module "app" {
  source = "./modules/app"

  internal_load_balancer = false

  vpc_id                = var.vpc_id
  app                   = local.app_id
  region                = var.region
  environment           = var.environment
  service_replicas      = var.service_replicas
  task_definition       = var.task_definition
  pipeline_image_tag    = var.pipeline_image_tag
  primary_domain        = var.primary_domain
  dns_name              = "${var.project}-${var.app}.${var.primary_domain}"
  certificate_arn       = var.certificate_arn
  kms_arn               = local.kms_arn
  repository_name       = var.repository_name
  enable_cpu_high_alarm = true
  enable_cpu_low_alarm  = false

  tags = merge(
    map("Last Updated", "${module.global.build_time}"),
    var.tags
  )
}


