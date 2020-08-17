data "aws_route53_zone" "primary" {
  name = var.primary_domain
}

resource "aws_route53_record" "dns" {
  zone_id = data.aws_route53_zone.primary.zone_id
  name    = var.dns_name
  type    = "A"

  alias {
    name                   = aws_lb.main.dns_name
    zone_id                = aws_lb.main.zone_id
    evaluate_target_health = true
  }
}


