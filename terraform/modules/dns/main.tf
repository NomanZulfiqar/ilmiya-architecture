variable "env" { type = string }
variable "vpc_id" { type = string }

# CNAME targets from PrivateLink endpoints
variable "atlas_endpoint_dns" { type = string }
variable "planetscale_endpoint_dns" { type = string }
variable "redis_endpoint_dns" { type = string }

# Original SaaS hostnames to override
variable "atlas_hostname" { type = string }
variable "planetscale_hostname" { type = string }
variable "redis_hostname" { type = string }

# --- Private Hosted Zones (one per SaaS domain) ---
# Pods resolve e.g. "cluster0.mongodb.net" → VPC endpoint private IP

resource "aws_route53_zone" "atlas" {
  name = var.atlas_hostname

  vpc {
    vpc_id = var.vpc_id
  }

  tags = { Name = "ilmiya-${var.env}-atlas-phz" }
}

resource "aws_route53_record" "atlas" {
  zone_id = aws_route53_zone.atlas.zone_id
  name    = var.atlas_hostname
  type    = "CNAME"
  ttl     = 300
  records = [var.atlas_endpoint_dns]
}

resource "aws_route53_zone" "planetscale" {
  name = var.planetscale_hostname

  vpc {
    vpc_id = var.vpc_id
  }

  tags = { Name = "ilmiya-${var.env}-planetscale-phz" }
}

resource "aws_route53_record" "planetscale" {
  zone_id = aws_route53_zone.planetscale.zone_id
  name    = var.planetscale_hostname
  type    = "CNAME"
  ttl     = 300
  records = [var.planetscale_endpoint_dns]
}

resource "aws_route53_zone" "redis" {
  name = var.redis_hostname

  vpc {
    vpc_id = var.vpc_id
  }

  tags = { Name = "ilmiya-${var.env}-redis-phz" }
}

resource "aws_route53_record" "redis" {
  zone_id = aws_route53_zone.redis.zone_id
  name    = var.redis_hostname
  type    = "CNAME"
  ttl     = 300
  records = [var.redis_endpoint_dns]
}
