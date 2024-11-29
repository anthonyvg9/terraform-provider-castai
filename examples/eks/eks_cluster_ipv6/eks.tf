# 2. Create EKS cluster.
module "eks" {
  source       = "terraform-aws-modules/eks/aws"
  version      = "19.4.2"
  putin_khuylo = true

  cluster_name                   = var.cluster_name
  cluster_version                = var.cluster_version
  cluster_endpoint_public_access = true

  cluster_ip_family          = "ipv6"
  create_cni_ipv6_iam_policy = true

  cluster_addons = {
    coredns = {
      most_recent = true
    }
    kube-proxy = {
      most_recent = true
    }
    vpc-cni = {
      most_recent = true
    }
  }

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  manage_aws_auth_configmap = true

  aws_auth_roles = [
    # Add the CAST AI IAM role which required for CAST AI nodes to join the cluster.
    {
      rolearn  = module.castai-eks-role-iam.instance_profile_role_arn
      username = "system:node:{{EC2PrivateDNSName}}"
      groups = [
        "system:bootstrappers",
        "system:nodes",
      ]
    },
  ]

  eks_managed_node_groups = {
    initial = {
      name           = "${var.cluster_name}-ng-2"
      instance_types = ["m5.large"]

      max_size     = 3
      min_size     = 2
      desired_size = 2
    }
  }
}

# Example additional security group.
resource "aws_security_group" "additional" {
  name_prefix = "${var.cluster_name}-additional"
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port = 22
    to_port   = 22
    protocol  = "tcp"
    cidr_blocks = [
      "10.0.0.0/8",
    ]
  }
}