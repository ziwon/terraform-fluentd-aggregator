variable "region" {
  type        = string
  default     = "ap-northeast-2"
  description = "The region of AWS to use"
}

variable "vpc_id" {
  type        = string
  description = "The Id of VPC to use"
}

variable "private_subnets" {
  type    = list(string)
  default = []
}

variable "public_subnets" {
  type    = list(string)
  default = []
}

variable "create_ecr" {
  default = false
}

variable "app" {
  type    = string
  default = "fluentd-aggregator"
}

variable "environment" {
## Inputs
  type    = string
  default = "dev"
}

variable "lb_protocol" {
  type    = string
  default = "TCP"
}

variable "internal_load_balancer" {
  default = "true"
}

# The path to the health check for the load balancer to know if the container(s) are ready
variable "health_check_url" {
  default = "/"
}

variable "lb_access_logs_expiration_days" {
  default = "3"
}

variable "app_autoscale_min_instances" {
  default = 1
}

variable "app_autoscale_max_instances" {
  default = 5
}

variable "service_replicas" {
  default = 1
}

variable "task_definition" {
  type = object({
    cpu             = number
    memory          = number
    container_name  = string
    container_image = string
    container_port  = number
    es_host         = string
    es_port         = number
    es_user         = string
    es_password     = string
    es_scheme       = string
    es_ssl_verify   = bool
  })
}

variable "enable_dns" {
  type    = bool
  default = false
}

variable "host_zone_id" {
}

variable "enable_cpu_high_alarm" {
  type    = bool
  default = true
}

variable "enable_cpu_low_alarm" {
  type    = bool
  default = false
}

variable "pipeline_image_tag" {
  type    = string
  default = "latest"
}

variable "primary_domain" {
  type    = string
  default = "d.restack.ml"
}

variable "dns_name" {
  type = string
}

variable "certificate_arn" {}

variable "repository_name" {}

variable "kms_arn" {}

variable "tags" {
  type = map
}
