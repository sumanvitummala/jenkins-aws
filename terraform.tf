# Step 1: AWS Provider
provider "aws" {
  region = "ap-south-1"   # Mumbai
}

# Step 2: Create VPC
resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "main-vpc"
  }
}

# Step 3: Create Internet Gateway
resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "main-gw"
  }
}

# Step 4: Create public subnet
resource "aws_subnet" "public_subnet" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true

  tags = {
    Name = "public-subnet"
  }
}

# Step 5: Route Table
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }

  tags = {
    Name = "public-rt"
  }
}

# Step 6: Associate Route Table with Subnet
resource "aws_route_table_association" "public_assoc" {
  subnet_id      = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.public.id
}

# Step 7: Security Group
resource "aws_security_group" "web_sg" {
  name   = "web_sg"
  vpc_id = aws_vpc.main.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # replace with actual
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "web-sg"
  }
}

# Step 8: EC2 Instance
resource "aws_instance" "my_ec2" {
  ami                         = "ami-0f9708d1cd2cfee41"  # Update if needed
  instance_type               = "t3.micro"
  key_name                    = "sumanvi-key"            # Ensure key exists
  subnet_id                   = aws_subnet.public_subnet.id
  associate_public_ip_address = true
  vpc_security_group_ids      = [aws_security_group.web_sg.id]

  tags = {
    Name = "Sumanvi-EC2"
  }
}

# Step 9: Elastic IP
resource "aws_eip" "web_eip" {
  instance   = aws_instance.my_ec2.id
  depends_on = [aws_instance.my_ec2]
}

# Step 10: Outputs
output "instance_id" {
  value       = aws_instance.my_ec2.id
  description = "The ID of the EC2 instance"
}

output "instance_public_ip" {
  value       = aws_eip.web_eip.public_ip
  description = "The Elastic IP of the EC2 instance"
}
