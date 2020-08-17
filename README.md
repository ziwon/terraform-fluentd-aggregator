# terraform-fluentd-aggregator

This repo was created for the purpose of storing logs collected from multiple swarm clusters on Elastic Search.

You may utilize my [fluent-bit-docker-metadata](https://github.com/ziwon/fluent-bit-docker-metadata) to ship logs to the aggregator from edge swarm cluster.

## Usage

Fluentd Aggregator runs as one ECS Fargate application, is deployed in a blue-green deployment, and routes the traffic load to the Network Load Balancer.

```
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

```

## Fluentd Configuration

As shown in the following configuration file, the collected logs are dynamically indexed to ElasticSearch according to the log properties using `record_transformer` filter and `elasticsearch dynamic` plugin. e.g.) `shinhan-aiagent`-2020.08.15

```
<filter docker.**>
  @type record_transformer
  <record>
    service_name ${tag_parts[1]}
  </record>
</filter>

<match docker.**>
  @type elasticsearch_dynamic

  host "#{ENV['ES_HOST'] || 'elasticsearch'}"
  port "#{ENV['ES_PORT'] || '9200'}"
  user "#{ENV['ES_USER'] || 'elastic'}"
  password "#{ENV['ES_PASSWORD'] || 'changeme'}"
  scheme "#{ENV['ES_SCHEME'] || 'http'}"
  ssl_verify "#{ENV['ES_SSL_VERIFY'] || 'false'}"
  ssl_version TLSv1_2

  logstash_format true
  logstash_dateformat %Y.%m.%d
  logstash_prefix ${record['biz_client']}-${record['service_name']}

  ...
```

## Local Swarm Cluster

On your mac, you can test the following pipeline by deploying a swarm cluster of four docker machines. Note that ES in your swarm dose run as standalone for testing.

```
fluent bit -> fluentd -> elastic search -> kibana
```

To deploy a swarm cluster:

```
$ make node-up
```

Build fluent-aggregator in docker-machine:

```
$ eval $(docker-machine env node-m1)
$ make docker-build
```

To start services:

```
$ make stack-start
```

You can access kibana with `http://192.168.128.101` since the host IP is always keep the same values even if the docker machine is deployed multiple times.

To change a certification with a customized domain:

```
$ DOMAIN=awesome.domain make node-gen-cert
```

## Requirements

| Name | Version |
|------|---------|
| terraform | ~> 0.12.0 |
| aws | ~> 2.57.0 |
| null | ~> 2.0 |

## Providers

| Name | Version |
|------|---------|
| aws | ~> 2.57.0 |
| null | ~> 2.0 |

## Environment Variables

We create and manage per-project isolated development environments according to the **12factor** using **`direnv`**

Chanege to local env:

```
$ make envrc-local
```

Change to prod env:

```
$ make envrc-prod
```

You may need to set up the following values in production with AWS Cloud and Elastic Cloud:

```
export PROJECT_NAME=ziwon
export APP_NAME=fluentd-aggregator

export AWS_ACCOUNT_ID=57xxxxxxxxxx
export AWS_REGION=ap-northeast-2
export AWS_PROFILE=default
export VPC_ID=vpc-xxxxxxxxx

export ECR_IMAGE_URL=${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${APP_NAME}
export TAG=latest

export ES_HOST=elastic.ap-northeast-1.aws.found.io
export ES_PORT=9243
export ES_USER=elastic
export ES_PASSWORD=changeme
export ES_SCHEME=https
export ES_SSL_VERIFY=true
```

## Makefile Targets

```
$ make
Usage: make [command] [args]
        Makefile:envrc-local             Change environment to local development       (e.g. make envrc-local)
        Makefile:envrc-prod              Change environment to prod development        (e.g. make envrc-prod)
        Makefile:help                    Show this help message                        (e.g. make help)
        docker.mk:docker-build           Build docker image                            (e.g. make docker-build)
        docker.mk:docker-commit          Commit current container using killed tag     (e.g. make docker-commit)
        docker.mk:docker-history         Show the history of an image                  (e.g. make docker-history)
        docker.mk:docker-push            Push an image to Amazon ECR registry          (e.g. make docker-push)
        docker.mk:docker-run             Run a command in a new container              (e.g. make docker-run)
        swarm.mk:node-add-cert           Add certification into the local machine      (e.g. make node-add-cert)
        swarm.mk:node-cleanup            Clean up the docker volume                    (e.g. make node-cleanup)
        swarm.mk:node-down               Terminate swarm nodes                         (e.g. make node-down)
        swarm.mk:node-gen-cert           Generate SSL certification                    (e.g. make node-gen-cert)
        swarm.mk:node-ip                 Show the address of node                      (e.g. make node-ip)
        swarm.mk:node-list               Show node list                                (e.g. make node-list)
        swarm.mk:node-up                 Bootstrap swarm nodes                         (e.g. make node-up)
        swarm.mk:stack-exec              Get executed the given command into container (e.g. make stack-exec sh)
        swarm.mk:stack-logs              Show logs from the service                    (e.g. make stack-logs elasticsearch)
        swarm.mk:stack-ps                List stack process                            (e.g. make stack-ps)
        swarm.mk:stack-reload            Reload the stack from swarm                   (e.g. make stack-reload)
        swarm.mk:stack-service           List stack services                           (e.g. make stack-service)
        swarm.mk:stack-start             Start the stack onto swarm                    (e.g. make stack-start)
        swarm.mk:stack-stop              Remove the stack from swarm                   (e.g. make stack-stop)
        swarm.mk:stack-viz               Visualize the swarm stack                     (e.g. make stack-viz)
```

## Inputs
(TBD)



## Outputs
(TBD)