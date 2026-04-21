env    = "prod"
region = "us-east-1"

vpc_cidr         = "10.0.0.0/16"
azs              = ["us-east-1a", "us-east-1b", "us-east-1c"]
private_subnets  = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
public_subnets   = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]
database_subnets = ["10.0.201.0/24", "10.0.202.0/24", "10.0.203.0/24"]

node_instance_types = ["m6i.xlarge"]
node_desired        = 3
node_min            = 2
node_max            = 10

atlas_endpoint_service       = "com.amazonaws.vpce.us-east-1.vpce-svc-xxxxxxxxxxxxxxxxx"
planetscale_endpoint_service = "com.amazonaws.vpce.us-east-1.vpce-svc-yyyyyyyyyyyyyyyyy"
redis_endpoint_service       = "com.amazonaws.vpce.us-east-1.vpce-svc-zzzzzzzzzzzzzzzzz"

atlas_hostname       = "cluster0-pl0.mongodb.net"
planetscale_hostname = "aws.connect.psdb.cloud"
redis_hostname       = "redis-12345.c1.us-east-1-1.ec2.cloud.redislabs.com"

github_org  = "ilmiya"
github_repo = "ilmiya-platform"
