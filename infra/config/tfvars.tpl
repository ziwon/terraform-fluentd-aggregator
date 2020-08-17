region = "{{ REGION }}"
vpc_id = "{{ VPC_ID }}"

project = "{{ PROJECT_NAME }}"
app = "{{ APP_NAME }}"
environment = "{{ ENV }}"

certificate_arn = "{{ CERTIFICATE_ARN }}"
kms_arn = "{{ KMS_ARN }}"


# Performance of a single aggregator task
#
# https://aws.amazon.com/blogs/compute/building-a-scalable-log-solution-aggregator-with-aws-fargate-fluentd-and-amazon-kinesis-data-firehose/
task_definition = {
  cpu = 1024
  memory = 2048
  container_name = "app"
  container_image = "{{ CONTAINER_IMAGE }}"
  container_port = {{ CONTAINER_PORT }}
  es_host = "{{ ES_HOST }}"
  es_port = {{ ES_PORT }}
  es_user = "{{ ES_USER }}"
  es_password = "{{ ES_PASSWORD }}"
  es_scheme = "{{ ES_SCHEME }}"
  es_ssl_verify = "{{ ES_SSL_VERIFY }}"
}

tags = {
  "Client" = "{{ CLIENT_NAME }}"
  "Terraform" = true
  "Environment" = "{{ ENV }}"
}
