
#======================ClusterName==================================
variable "cluster_name" {
  type    = string
  default = "dev-cls01"
}

#======================ClusterConfiguration==================================
resource "aws_eks_cluster" "eks_cluster" {
  name     = var.cluster_name
  role_arn = aws_iam_role.eks_cls_Role.arn
  version = 1.19
  
  enabled_cluster_log_types = ["api", "audit", "controllerManager", "scheduler", "authenticator"]

  vpc_config {
    subnet_ids = module.vpc.public_subnets
    endpoint_public_access = true 
  }

  kubernetes_network_config {
      service_ipv4_cidr = "10.124.0.0/14" # Usable 10.124.0.1 - 10.127.255.254 = 262,142
  }

  tags = {
    Terraform = "true"
  }
  # Ensure that IAM Role permissions are created before and deleted after EKS Cluster handling.
  # Otherwise, EKS will not be able to properly delete EKS managed EC2 infrastructure such as Security Groups.
  depends_on = [
    aws_iam_role_policy_attachment.eks_cls_policy,
    aws_iam_role_policy_attachment.eks_cls_VPCResourceController_policy,
    aws_cloudwatch_log_group.eks_cls_Loggroup,
  ]
}

output "endpoint" {
  value = aws_eks_cluster.eks_cluster.endpoint
}

output "kubeconfig-certificate-authority-data" {
  value = aws_eks_cluster.eks_cluster.certificate_authority[0].data
}

# Exports cluster_security_group_id and vpc_id 
output "cls_vpc_config" {
  value = aws_eks_cluster.eks_cluster.vpc_config 
}
#============================IAM-Role================================
resource "aws_iam_role" "eks_cls_Role" {
  name = "${var.cluster_name}-eks_cls_Role"

  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "eks.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
POLICY
}

# EKS cluster policy
resource "aws_iam_role_policy_attachment" "eks_cls_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.eks_cls_Role.name
}

# Policy used by VPC Resource Controller to manage ENI and IPs for worker nodes
# Optionally, enable Security Groups for Pods
# Reference: https://docs.aws.amazon.com/eks/latest/userguide/security-groups-for-pods.html
resource "aws_iam_role_policy_attachment" "eks_cls_VPCResourceController_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSVPCResourceController"
  role       = aws_iam_role.eks_cls_Role.name
}

#======================ClusterLog==================================
resource "aws_cloudwatch_log_group" "eks_cls_Loggroup" {
    name              = "/aws/eks/${var.cluster_name}/cluster"
    retention_in_days = 7
}