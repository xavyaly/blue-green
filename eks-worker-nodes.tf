resource "aws_iam_role" "eks_node_role"{
    name = "eks_node_role"
    assume_role_policy = jsonencode({
        Version = "2012-10-17"
        Statement = [
        {
            Action = "sts:AssumeRole"
            Effect = "Allow"
            Sid    = ""
            Principal = {
            Service = "ec2.amazonaws.com"
            }
        },
        ]
    })  
}
resource "aws_iam_role_policy_attachment" "eks_node_policy"{
  role       = aws_iam_role.eks_node_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}
resource "aws_iam_role_policy_attachment" "eks_CNI_policy"{
  role       = aws_iam_role.eks_node_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
}
resource "aws_iam_role_policy_attachment" "eks_ec2_policy"{
  role       = aws_iam_role.eks_node_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

resource "aws_security_group" "eks_security_group_node" {
  name        = "eks_security_group_node"
  description = "Allow TLS inbound and outbound traffic"
  vpc_id      = aws_vpc.eks_vpc.id

  ingress {
    description      = "TLS from VPC"
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
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

resource "aws_eks_node_group" "eks_node_group" {
  cluster_name    = aws_eks_cluster.eks_cluster_demo.name
  node_group_name = "eks_node_group"
  node_role_arn   = aws_iam_role.eks_node_role.arn
  subnet_ids = [aws_subnet.eks_subnet_1.id, aws_subnet.eks_subnet_2.id]

  scaling_config {
    desired_size = 2
    max_size     = 4
    min_size     = 1
  }
  # Type of capacity associated with the EKS Node Group. 
  # Valid values: ON_DEMAND, SPOT
  capacity_type = "ON_DEMAND"

  launch_template {
    name = aws_launch_template.eks_node_launch_template.name
    version = aws_launch_template.eks_node_launch_template.latest_version
  }

  # Lifecycle
  lifecycle {
    create_before_destroy = true
  }

  # Ensure that IAM Role permissions are created before and deleted after EKS Node Group handling.
  # Otherwise, EKS will not be able to properly delete EC2 Instances and Elastic Network Interfaces.
  depends_on = [
    aws_iam_role_policy_attachment.eks_node_policy,
    aws_iam_role_policy_attachment.eks_CNI_policy,
    aws_iam_role_policy_attachment.eks_ec2_policy,
  ]
}
resource "aws_security_group" "eks_node_security_group" {
  name        = "eks_node_security_group"
  description = "Allow TLS inbound and outbound traffic"
  vpc_id      = aws_vpc.eks_vpc.id

  ingress {
    description      = "NodePort port"
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
resource "aws_launch_template" "eks_node_launch_template" {
  name = "eks_node_launch_template"

  vpc_security_group_ids = [aws_security_group.eks_node_security_group.id, aws_eks_cluster.eks_cluster_demo.vpc_config[0].cluster_security_group_id]
   
  tag_specifications {
    resource_type = "instance"

    tags = {
      Name = "EKS-MANAGED-NODE"

    }
  }

}
