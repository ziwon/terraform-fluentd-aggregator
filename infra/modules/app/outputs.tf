output "private_subnets" {
  value = data.aws_subnet_ids.private
}

output "public_subnets" {
  value = data.aws_subnet_ids.public
}

output "ecs_cluster_id" {
  value = concat(aws_ecs_cluster.main.*.id, [""])[0]
}

output "ecs_cluster_arn" {
  value = concat(aws_ecs_cluster.main.*.arn, [""])[0]
}

output "main_lb_id" {
  value = concat(aws_lb.main.*.id, [""])[0]
}

output "main_lb_arn" {
  value = concat(aws_lb.main.*.arn, [""])[0]
}

output "main_lb_dns_name" {
  value = concat(aws_lb.main.*.dns_name, [""])[0]
}

output "main_lb_zone_id" {
  value = concat(aws_lb.main.*.zone_id, [""])[0]
}

output "tcp_listener_arns" {
  value = aws_lb_listener.tcp.*.arn
}

output "tcp_listener_ids" {
  value = aws_lb_listener.tcp.*.id
}

output "target_group_arns" {
  value = [
    aws_lb_target_group.blue.*.arn,
    aws_lb_target_group.green.*.arn,
  ]
}

output "target_group_names" {
  value = [
    aws_lb_target_group.blue.*.name,
    aws_lb_target_group.green.*.name
  ]
}

output "codedeploy_app_id" {
  value = aws_codedeploy_app.main.id
}

output "codedeploy_deployment_group_id" {
  value = aws_codedeploy_deployment_group.main.id
}

output "dns_name" {
  value = aws_route53_record.dns.name
}
