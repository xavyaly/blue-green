resource "aws_vpc" "eks_vpc" {
  #VPC cidir block
  cidr_block = "10.0.0.0/16"

  # VPC tags
  tags = {
    Name                        = "terraform_eks_cluster_demo"
    "kubernetes.io/cluster/${var.cluster-name}" = "shared"
    "kubernetes.io/role/elb"    = 1
  }
}

# Subnet in one AZ(ap-south-1a)
resource "aws_subnet" "eks_subnet_1" { 
  # The VPC ID.
  vpc_id     = aws_vpc.eks_vpc.id

  # The CIDR block for the subnet.
  cidr_block = "10.0.0.0/24"

  # The AZ for the subnet.
  availability_zone = "ap-south-1a"

  # A map of tags to assign to the resource.
  tags = {
    Name                        = "eks_subnet-ap-south-1a"
    "kubernetes.io/cluster/${var.cluster-name}" = "shared"
    "kubernetes.io/role/elb"    = 1
  }
  # Required for EKS. Instances launched into the subnet should be assigned a public IP address.
  map_public_ip_on_launch = true
}

# Subnet in second AZ(ap-south-2a)
resource "aws_subnet" "eks_subnet_2" { 
  # The VPC ID.
  vpc_id     = aws_vpc.eks_vpc.id

  # The CIDR block for the subnet.
  cidr_block = "10.0.1.0/24"

  # The AZ for the subnet.
  availability_zone = "ap-south-1b"

  # A map of tags to assign to the resource.
  tags = {
    Name                        = "eks_subnet-ap-south-2a"
    "kubernetes.io/cluster/${var.cluster-name}" = "shared"
    "kubernetes.io/role/elb"    = 1
  }

  # Required for EKS. Instances launched into the subnet should be assigned a public IP address.
  map_public_ip_on_launch = true
}

# Internet Gateway Resource
resource "aws_internet_gateway" "eks_IGW" {
  vpc_id = aws_vpc.eks_vpc.id
}

# Route table resouce and route to IGW
resource "aws_route_table" "eks_route_table" {
  vpc_id = aws_vpc.eks_vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.eks_IGW.id
  }
}

# Route table association to public subnets_1
resource "aws_route_table_association" "eks_route_association_eks_subnet_1" {
  subnet_id      = aws_subnet.eks_subnet_1.id
  route_table_id = aws_route_table.eks_route_table.id
}

# Route table association to public subnets_2
resource "aws_route_table_association" "eks_route_association_eks_subnet_2" {
  subnet_id      = aws_subnet.eks_subnet_2.id
  route_table_id = aws_route_table.eks_route_table.id
}
