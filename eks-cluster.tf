resource "aws_iam_role" "eks_role_demo" {
  name = "eks_demo"

  # Terraform's "jsonencode" function converts a
  # Terraform expression result to valid JSON syntax.
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "eks.amazonaws.com"
        }
      },
    ]
  })

  tags = {
    Name = "eks_cluster"
  }
}
resource "aws_iam_role_policy_attachment" "eks_cluster_policy"{
  role       = aws_iam_role.eks_role_demo.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}
resource "aws_iam_role_policy_attachment" "eks_cluster_vpc_policy"{
  role       = aws_iam_role.eks_role_demo.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSVPCResourceController"
}
resource "aws_security_group" "eks_security_group" {
  name        = "eks_security_group"
  description = "Allow TLS inbound and outbound traffic"
  vpc_id      = aws_vpc.eks_vpc.id

  ingress {
    description      = "TLS from VPC"
    from_port        = 443
    to_port          = 443
    protocol         = "tcp"
    cidr_blocks      = [aws_vpc.eks_vpc.cidr_block]
  }

  ingress {
    description      = "Nodeport ports"
    from_port        = 30000
    to_port          = 32767
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
   }
}
resource "aws_eks_cluster" "eks_cluster_demo" {
  name     = var.cluster-name
  role_arn = aws_iam_role.eks_role_demo.arn

  vpc_config {
    security_group_ids = [aws_security_group.eks_security_group.id]
    subnet_ids = [aws_subnet.eks_subnet_1.id, aws_subnet.eks_subnet_2.id]
  }

  # Ensure that IAM Role permissions are created before and deleted after EKS Cluster handling.
  # Otherwise, EKS will not be able to properly delete EKS managed EC2 infrastructure such as Security Groups.
  depends_on = [
    aws_iam_role_policy_attachment.eks_cluster_policy,
    aws_iam_role_policy_attachment.eks_cluster_vpc_policy,
  ]
}
