terraform {
  required_version = ">= 1.5"
  required_providers {
    aws = { source = "hashicorp/aws", version = "~> 5.0" }
    tls = { source = "hashicorp/tls", version = "~> 4.0" }
  }
  backend "s3" {
    bucket         = "ilmiya-terraform-state"
    dynamodb_table = "ilmiya-terraform-lock"
    encrypt        = true
    # key + region set via -backend-config per env
  }
}

provider "aws" { region = var.region }

variable "region" {
  type    = string
  default = "us-east-1"
}
variable "env" { type = string }
variable "vpc_cidr" { type = string }
variable "azs" { type = list(string) }
variable "private_subnets" { type = list(string) }
variable "public_subnets" { type = list(string) }
variable "database_subnets" { type = list(string) }
variable "node_instance_types" { type = list(string) }
variable "node_desired" { type = number }
variable "node_min" {
  type    = number
  default = 1
}
variable "node_max" { type = number }
variable "atlas_endpoint_service" { type = string }
variable "planetscale_endpoint_service" { type = string }
variable "redis_endpoint_service" { type = string }
variable "atlas_hostname" { type = string }
variable "planetscale_hostname" { type = string }
variable "redis_hostname" { type = string }
variable "github_org" { type = string }
variable "github_repo" { type = string }

data "aws_caller_identity" "current" {}

module "vpc" {
  source           = "../modules/vpc"
  env              = var.env
  vpc_cidr         = var.vpc_cidr
  azs              = var.azs
  private_subnets  = var.private_subnets
  public_subnets   = var.public_subnets
  database_subnets = var.database_subnets
}

module "eks" {
  source              = "../modules/eks"
  env                 = var.env
  vpc_id              = module.vpc.vpc_id
  private_subnet_ids  = module.vpc.private_subnet_ids
  node_instance_types = var.node_instance_types
  node_desired        = var.node_desired
  node_min            = var.node_min
  node_max            = var.node_max
}

module "privatelink" {
  source                       = "../modules/privatelink"
  env                          = var.env
  vpc_id                       = module.vpc.vpc_id
  database_subnet_ids          = module.vpc.database_subnet_ids
  region                       = var.region
  atlas_endpoint_service       = var.atlas_endpoint_service
  planetscale_endpoint_service = var.planetscale_endpoint_service
  redis_endpoint_service       = var.redis_endpoint_service
}

module "dns" {
  source                   = "../modules/dns"
  env                      = var.env
  vpc_id                   = module.vpc.vpc_id
  atlas_endpoint_dns       = module.privatelink.atlas_endpoint_dns
  planetscale_endpoint_dns = module.privatelink.planetscale_endpoint_dns
  redis_endpoint_dns       = module.privatelink.redis_endpoint_dns
  atlas_hostname           = var.atlas_hostname
  planetscale_hostname     = var.planetscale_hostname
  redis_hostname           = var.redis_hostname
}

module "secrets" {
  source            = "../modules/secrets"
  env               = var.env
  oidc_provider_arn = module.eks.oidc_provider_arn
  oidc_provider_url = module.eks.oidc_provider_url
}

module "iam" {
  source          = "../modules/iam"
  env             = var.env
  github_org      = var.github_org
  github_repo     = var.github_repo
  eks_cluster_arn = "arn:aws:eks:${var.region}:${data.aws_caller_identity.current.account_id}:cluster/${module.eks.cluster_name}"
}

output "eks_cluster_endpoint" { value = module.eks.cluster_endpoint }
output "github_terraform_role" { value = module.iam.github_terraform_role_arn }
output "external_secrets_role" { value = module.secrets.external_secrets_role_arn }
