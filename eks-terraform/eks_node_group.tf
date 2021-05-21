resource "aws_eks_node_group" "eks_cls_ng" {
  cluster_name    = aws_eks_cluster.eks_cluster.name
  node_group_name = "${var.cluster_name}-worker"
  node_role_arn   = aws_iam_role.eks_NodeGroup_role.arn
  subnet_ids      = module.vpc.public_subnets

  scaling_config {
    desired_size = 1
    max_size     = 3
    min_size     = 1
  }

  capacity_type = "SPOT"
  disk_size = 8
  instance_types = ["t3.small", "t3.medium"]
  ami_type = "AL2_x86_64"

  remote_access {
      ec2_ssh_key = "Play"  
  }

  # Optional: Allow external changes without Terraform plan difference
  lifecycle {
    ignore_changes = [scaling_config[0].desired_size]
  }
  tags = {
    "k8s.io/cluster-autoscaler/enabled" = "yes"
    "k8s.io/cluster-autoscaler/${var.cluster_name}" = "yes"
  }
  # Ensure that IAM Role permissions are created before and deleted after EKS Node Group handling.
  # Otherwise, EKS will not be able to properly delete EC2 Instances and Elastic Network Interfaces.
  depends_on = [
    aws_iam_role_policy_attachment.eks_NodeGroup_worker_policy,
    aws_iam_role_policy_attachment.eks_NodeGroup_EKS_CNI_policy,
    aws_iam_role_policy_attachment.eks_NodeGroup_Read_Container_Registry_policy,
  ]
}
# EKS Node Group IAM Role
resource "aws_iam_role" "eks_NodeGroup_role" {
  name = "${var.cluster_name}-eks_ngroup_role"

  assume_role_policy = jsonencode({
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
    Version = "2012-10-17"
  })
}

resource "aws_iam_role_policy_attachment" "eks_NodeGroup_worker_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.eks_NodeGroup_role.name
}

resource "aws_iam_role_policy_attachment" "eks_NodeGroup_EKS_CNI_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.eks_NodeGroup_role.name
}

resource "aws_iam_role_policy_attachment" "eks_NodeGroup_Read_Container_Registry_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.eks_NodeGroup_role.name
}