variable "env" { type = string }
variable "vpc_id" { type = string }
variable "database_subnet_ids" { type = list(string) }
variable "region" { type = string }

# Service names — these come from each SaaS provider's PrivateLink setup
variable "atlas_endpoint_service" { type = string }
variable "planetscale_endpoint_service" { type = string }
variable "redis_endpoint_service" { type = string }

resource "aws_security_group" "privatelink" {
  name_prefix = "ilmiya-${var.env}-privatelink-"
  vpc_id      = var.vpc_id

  ingress {
    description = "MongoDB"
    from_port   = 27017
    to_port     = 27017
    protocol    = "tcp"
    cidr_blocks = [data.aws_vpc.current.cidr_block]
  }

  ingress {
    description = "MySQL (PlanetScale)"
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = [data.aws_vpc.current.cidr_block]
  }

  ingress {
    description = "Redis"
    from_port   = 6379
    to_port     = 6379
    protocol    = "tcp"
    cidr_blocks = [data.aws_vpc.current.cidr_block]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "ilmiya-${var.env}-privatelink-sg" }
}

data "aws_vpc" "current" { id = var.vpc_id }

resource "aws_vpc_endpoint" "atlas" {
  vpc_id              = var.vpc_id
  service_name        = var.atlas_endpoint_service
  vpc_endpoint_type   = "Interface"
  subnet_ids          = var.database_subnet_ids
  security_group_ids  = [aws_security_group.privatelink.id]
  private_dns_enabled = false # handled via Route53

  tags = { Name = "ilmiya-${var.env}-atlas-vpce" }
}

resource "aws_vpc_endpoint" "planetscale" {
  vpc_id              = var.vpc_id
  service_name        = var.planetscale_endpoint_service
  vpc_endpoint_type   = "Interface"
  subnet_ids          = var.database_subnet_ids
  security_group_ids  = [aws_security_group.privatelink.id]
  private_dns_enabled = false

  tags = { Name = "ilmiya-${var.env}-planetscale-vpce" }
}

resource "aws_vpc_endpoint" "redis" {
  vpc_id              = var.vpc_id
  service_name        = var.redis_endpoint_service
  vpc_endpoint_type   = "Interface"
  subnet_ids          = var.database_subnet_ids
  security_group_ids  = [aws_security_group.privatelink.id]
  private_dns_enabled = false

  tags = { Name = "ilmiya-${var.env}-redis-vpce" }
}

output "atlas_endpoint_dns" { value = aws_vpc_endpoint.atlas.dns_entry[0].dns_name }
output "planetscale_endpoint_dns" { value = aws_vpc_endpoint.planetscale.dns_entry[0].dns_name }
output "redis_endpoint_dns" { value = aws_vpc_endpoint.redis.dns_entry[0].dns_name }
output "privatelink_sg_id" { value = aws_security_group.privatelink.id }
