resource "aws_vpc" "my-vpc" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "Capstone VPC"
  }
}

# Public Subnet 201-a
resource "aws_subnet" "my-public-201-a" {
  vpc_id                  = aws_vpc.my-vpc.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true

  tags = {
      Name = "my-public-201-a"
      "kubernetes.io/cluster/my-eks-201" = "shared"
      "kubernetes.io/role/elb" = 1
  }
}

# Public Subnet 201-b
resource "aws_subnet" "my-public-201-b" {
  vpc_id                  = aws_vpc.my-vpc.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "us-east-1b"
  map_public_ip_on_launch = true

  tags = {
      Name = "my-public-201-b"
      "kubernetes.io/cluster/my-eks-201" = "shared"
      "kubernetes.io/role/elb" = 1
  }
}

# Private Subnet 201-a
resource "aws_subnet" "my-private-201-a" {
  vpc_id                  = aws_vpc.my-vpc.id
  cidr_block              = "10.0.11.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = false

  tags = {
      Name = "my-private-201-a"
      "kubernetes.io/cluster/my-eks-201" = "shared"
      "kubernetes.io/role/internal-elb" = 1
  }
}

# Private Subnet 201-b
resource "aws_subnet" "my-private-201-b" {
  vpc_id                  = aws_vpc.my-vpc.id
  cidr_block              = "10.0.12.0/24"
  availability_zone       = "us-east-1b"
  map_public_ip_on_launch = false

  tags = {
      Name = "my-private-201-b"
      "kubernetes.io/cluster/my-eks-201" = "shared"
      "kubernetes.io/role/internal-elb" = 1
  }
}

# Internet Gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.my-vpc.id

  tags = {
    Name = "IGW"
  }
}

# Route Table for public subnet
resource "aws_route_table" "public-rt" {
  vpc_id = aws_vpc.my-vpc.id


  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "PublicRT"
  }
}


# Associate Public Subnets with route table
resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.my-public-201-a.id
  route_table_id = aws_route_table.public-rt.id
}

resource "aws_route_table_association" "b" {
  subnet_id      = aws_subnet.my-public-201-b.id
  route_table_id = aws_route_table.public-rt.id
}

# NAT Gateway

resource "aws_eip" "Nat-Gateway-EIP" {
  vpc = true
}



resource "aws_nat_gateway" "nat-gw" {
  depends_on = [
    aws_eip.Nat-Gateway-EIP
  ]
  allocation_id = aws_eip.Nat-Gateway-EIP.id
  subnet_id         = aws_subnet.my-public-201-a.id
}

resource "aws_route_table" "NAT-Gateway-RT" {
  depends_on = [
    aws_nat_gateway.nat-gw
  ]

  vpc_id = aws_vpc.my-vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat-gw.id
  }

  tags = {
    Name = "Route Table for NAT Gateway"
  }

}

resource "aws_route_table_association" "Nat-Gateway-RT-Association" {
  depends_on = [
    aws_route_table.NAT-Gateway-RT
  ]

#  Private Subnet ID for adding this route table to the DHCP server of Private subnet!
  subnet_id      = aws_subnet.my-private-201-a.id

# Route Table ID
  route_table_id = aws_route_table.NAT-Gateway-RT.id
}


# Security Groups
module "pub-sec-group" {
  source = "terraform-aws-modules/security-group/aws"

  name        = "pub-sec-group"
  description = "Public Security Group: Port 22 for Ingress and all ports for egress"
  vpc_id      = aws_vpc.my-vpc.id
  egress_with_cidr_blocks = [
    {
      from_port   = 0
      to_port     = 65535
      protocol    = "all"
      description = "Allow egress traffic"
      cidr_blocks = "0.0.0.0/0"
    }
  ]

  ingress_with_cidr_blocks = [

    {
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      description = "SSH"
      cidr_blocks = "0.0.0.0/0"
    }
  ]
}


module "pri-sec-group" {
  source = "terraform-aws-modules/security-group/aws"

  name        = "pri-sec-group"
  description = "Traffic for private subnet"
  vpc_id      = aws_vpc.my-vpc.id
  egress_with_cidr_blocks = [
    {
      from_port   = 0
      to_port     = 65535
      protocol    = "all"
      description = "Allow egress traffic"
      cidr_blocks = "0.0.0.0/0"
    }
  ]

  ingress_with_cidr_blocks = [

    {
      from_port   = 0
      to_port     =65535
      protocol    = "all"
      description = "Allow ingress traffic only from VPC CIDR block"
      cidr_blocks = "10.0.0.0/16"
    }
  ]
}

# Output ID's for VPC and Subnets
output "vpc_id"{
    description = "VPC ID"
    value = aws_vpc.my-vpc.id
}

output "my-public-201-a-id"{
    description = "ID of my-public-201-a"
    value = aws_subnet.my-public-201-a.id
}

output "my-public-201-b-id"{
    description = "ID of my-public-201-b"
    value = aws_subnet.my-public-201-b.id
}

output "my-private-201-a-id"{
    description = "ID of my-private-201-a"
    value = aws_subnet.my-private-201-a.id
}

output "my-private-201-b-id"{
    description = "ID of my-private-201-b"
    value = aws_subnet.my-private-201-b.id
}

