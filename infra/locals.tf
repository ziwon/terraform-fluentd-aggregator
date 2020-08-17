locals {
  proj_id = "${var.project}-${var.app}"
  // Use var.environment for app_id with `dev` only
  app_id  = var.environment == "dev" ? "${var.project}-${var.app}-${var.environment}" : "${var.project}-${var.app}"
  kms_arn = var.kms_arn == "" ? "*" : var.kms_arn
}
