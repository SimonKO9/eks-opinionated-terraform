
data "aws_availability_zones" "available" {}

locals {
  vpc_name     = "simon-eks-vpc"
  cluster_name = "simon-eks-cluster"
  bastion_host_enabled = false
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "3.2.0"

  name                 = local.vpc_name
  cidr                 = "10.0.0.0/16"
  azs                  = data.aws_availability_zones.available.names
  private_subnets      = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  public_subnets       = ["10.0.4.0/24", "10.0.5.0/24", "10.0.6.0/24"]
  enable_nat_gateway   = true
  single_nat_gateway   = true
  enable_dns_hostnames = true

  tags = {
    "kubernetes.io/cluster/${local.cluster_name}" = "shared"
  }

  public_subnet_tags = {
    "kubernetes.io/cluster/${local.cluster_name}" = "shared"
    "kubernetes.io/role/elb"                      = "1"
  }

  private_subnet_tags = {
    "kubernetes.io/cluster/${local.cluster_name}" = "shared"
    "kubernetes.io/role/internal-elb"             = "1"
  }
}

module "aws_key_pair" {
  source  = "cloudposse/key-pair/aws"
  version = "0.18.0"

  attributes          = ["ssh", "key"]
  ssh_public_key_path = "./secrets" # expects a key at ./secrets/ssh-key.pub
  generate_ssh_key    = false
}

module "bastion" {
  source  = "cloudposse/ec2-bastion-server/aws"
  version = "0.30.0"

  name                        = "aws-bastion"
  enabled                     = local.bastion_host_enabled
  instance_type               = "t2.micro"
  security_groups             = [module.vpc.default_security_group_id]
  subnets                     = module.vpc.public_subnets
  key_name                    = module.aws_key_pair.key_name
  vpc_id                      = module.vpc.vpc_id
  associate_public_ip_address = true
}