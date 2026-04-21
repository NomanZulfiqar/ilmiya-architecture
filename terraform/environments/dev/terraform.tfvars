env    = "dev"
region = "us-east-1"

vpc_cidr         = "10.2.0.0/16"
azs              = ["us-east-1a", "us-east-1b"]
private_subnets  = ["10.2.1.0/24", "10.2.2.0/24"]
public_subnets   = ["10.2.101.0/24", "10.2.102.0/24"]
database_subnets = ["10.2.201.0/24", "10.2.202.0/24"]

node_instance_types = ["t3.large"]
node_desired        = 1
node_max            = 3

atlas_endpoint_service       = "com.amazonaws.vpce.us-east-1.vpce-svc-xxxxxxxxxxxxxxxxx"
planetscale_endpoint_service = "com.amazonaws.vpce.us-east-1.vpce-svc-yyyyyyyyyyyyyyyyy"
redis_endpoint_service       = "com.amazonaws.vpce.us-east-1.vpce-svc-zzzzzzzzzzzzzzzzz"

atlas_hostname       = "cluster0-dev-pl0.mongodb.net"
planetscale_hostname = "aws.connect.psdb.cloud"
redis_hostname       = "redis-dev-12345.c1.us-east-1-1.ec2.cloud.redislabs.com"

github_org  = "ilmiya"
github_repo = "ilmiya-platform"
