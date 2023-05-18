/* # Define AWS provider
provider "aws" {
  region = "us-west-2" # Specify your desired AWS region
} */

# Create VPC
resource "aws_vpc" "eks_vpc" {
  cidr_block = "10.0.0.0/16" # Specify the desired CIDR block for the VPC

  tags = {
    Name = "eks-vpc"
  }
}

# Create Subnets
resource "aws_subnet" "eks_subnets" {
  count         = 2
  vpc_id        = aws_vpc.eks_vpc.id
  cidr_block    = cidrsubnet(aws_vpc.eks_vpc.cidr_block, 8, count.index) # Create subnets with /24 CIDR blocks

  tags = {
    Name = "eks-subnet-${count.index}"
  }
}

# Create Security Group
resource "aws_security_group" "eks_sg" {
  vpc_id = aws_vpc.eks_vpc.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Allow SSH access from anywhere
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"] # Allow all outbound traffic
  }

  tags = {
    Name = "eks-security-group"
  }
}

# Create IAM role for EKS
resource "aws_iam_role" "eks_cluster_role" {
  name = "eks-cluster-role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Principal": {
        "Service": "eks.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

# Attach required policies to IAM role
resource "aws_iam_role_policy_attachment" "eks_cluster_policy_attachment" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.eks_cluster_role.name
}

# Create EKS cluster
resource "aws_eks_cluster" "eks_cluster" {
  name     = "eks-cluster"
  role_arn = aws_iam_role.eks_cluster_role.arn
  vpc_config {
    subnet_ids = aws_subnet.eks_subnets[*].id
    security_group_ids = [aws_security_group.eks_sg.id]
  }
}

/* # Output kubeconfig
output "kubeconfig" {
  value = aws_eks_cluster.eks_cluster.kubeconfig[*].content
} */
