variable "region" {
  type    = string
  default = "ap-northeast-2"
}

variable "vpc_id" {
  type = string
}

variable "project" {
  type    = string
  default = "ziwon"
}

variable "app" {
  type    = string
  default = "fluentd-aggregator"
}

# dev | prod
variable "environment" {
  type    = string
  default = "dev"
}

variable "service_replicas" {
  type    = number
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
  default = {
    cpu             = 512
    memory          = 1024
    container_name  = "app"
    container_image = "ziwon/fluentd_aggregator"
    container_port  = 24224
    es_host         = "elasticsearch"
    es_port         = 9200
    es_user         = "elastic"
    es_scheme       = "http"
    es_password     = "changeme"
    es_ssl_verify   = false
  }
}

variable "pipeline_image_tag" {
  type    = string
  default = "latest"
}

variable "primary_domain" {
  type    = string
  default = "d.restack.ml"
}

variable "certificate_arn" {
  type = string
}

variable "repository_name" {
  type    = string
  default = "fluentd-aggregator"
}

variable "kms_arn" {
  type = string
}

variable "tags" {
  type = map(string)
}
