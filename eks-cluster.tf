data "aws_eks_cluster" "cluster" {
  name = module.eks.cluster_id
}

data "aws_eks_cluster_auth" "cluster" {
  name = module.eks.cluster_id
}

data "aws_caller_identity" "current" {}

locals {
  tags = {
    Environment = "dev"
    Terraform   = "true"
  }
}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 18.0"

  cluster_name    = local.cluster_name
  cluster_version = "1.22"

  cluster_endpoint_private_access = true
  cluster_endpoint_public_access  = true

  # required for the LB controller to receive webhook from k8s control plane
  node_security_group_additional_rules = {
    ingress_allow_access_from_control_plane = {
      type                          = "ingress"
      protocol                      = "tcp"
      from_port                     = 9443
      to_port                       = 9443
      source_cluster_security_group = true
      description                   = "Allow access from control plane to webhook port of AWS load balancer controller"
    }
  }

  # TODO IRSA
  cluster_addons = {
    coredns = {
      resolve_conflicts = "OVERWRITE"
    }
    kube-proxy = {}
    vpc-cni = {
      resolve_conflicts        = "OVERWRITE"
      service_account_role_arn = module.vpc_cni_irsa.iam_role_arn
    }
  }

  #  TODO
  #  cluster_encryption_config = [{
  #    provider_key_arn = "arn:aws:kms:eu-west-1:111122223333:key/1234abcd-12ab-34cd-56ef-1234567890ab"
  #    resources        = ["secrets"]
  #  }]

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets


  # EKS Managed Node Group(s)
  eks_managed_node_group_defaults = {
    disk_size                              = 50
    iam_role_attach_cni_policy             = true
    update_launch_template_default_version = true
  }

  eks_managed_node_groups = {
    blue = {
      min_size     = 1
      max_size     = 3
      desired_size = 2

      instance_types = ["t2.medium"]
      capacity_type  = "SPOT"
    }
  }

  # aws-auth configmap
  manage_aws_auth_configmap = true

  aws_auth_accounts = [
    data.aws_caller_identity.current.account_id
  ]

  tags = local.tags
}



module "vpc_cni_irsa" {
  source = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"

  role_name             = "vpc_cni"
  attach_vpc_cni_policy = true
  vpc_cni_enable_ipv4   = true

  oidc_providers = {
    main = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["kube-system:aws-node"]
    }
  }

  tags = local.tags
}

# the following two are required for nginx to receive webhooks
resource "aws_security_group_rule" "webhook_admission_inbound" {
  type                     = "ingress"
  from_port                = 8443
  to_port                  = 8443
  protocol                 = "tcp"
  security_group_id        = module.eks.node_security_group_id
  source_security_group_id = module.eks.cluster_primary_security_group_id
}

resource "aws_security_group_rule" "webhook_admission_outbound" {
  type                     = "egress"
  from_port                = 8443
  to_port                  = 8443
  protocol                 = "tcp"
  security_group_id        = module.eks.node_security_group_id
  source_security_group_id = module.eks.cluster_primary_security_group_id
}
