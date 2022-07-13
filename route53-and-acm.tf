locals {
  domain_name = "simonko.xyz"
}

data "aws_route53_zone" "domain_zone" {
  name = "${local.domain_name}."
}

module "acm" {
  source = "terraform-aws-modules/acm/aws"

  domain_name = local.domain_name
  zone_id     = data.aws_route53_zone.domain_zone.zone_id

  wait_for_validation = true

  tags = {
    Name = local.domain_name
  }
}