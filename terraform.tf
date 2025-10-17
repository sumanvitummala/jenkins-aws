# Step 1: Specify AWS provider
provider "aws" {
  region = "ap-south-1"
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

# Step 3: Create Public Subnet
resource "aws_subnet" "public_subnet" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "ap-south-1a"

  tags = {
    Name = "public-subnet"
  }
}

# Step 4: Security Group
resource "aws_security_group" "web_sg" {
  name   = "web_sg"
  vpc_id = aws_vpc.main.id

  # SSH from anywhere for testing (change to Jenkins IP later)
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # HTTP access from anywhere
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

# Step 5: EC2 Instance
resource "aws_instance" "my_ec2" {
  ami                         = "ami-0f9708d1cd2cfee41"  # Update your preferred AMI
  instance_type               = "t3.micro"
  key_name                    = "sumanvi-key"           # Replace with your key
  subnet_id                   = aws_subnet.public_subnet.id
  associate_public_ip_address = true
  vpc_security_group_ids      = [aws_security_group.web_sg.id]

  tags = {
    Name = "Sumanvi-EC2"
  }
}

# Step 6: Allocate Elastic IP
resource "aws_eip" "web_eip" {
  instance   = aws_instance.my_ec2.id
  depends_on = [aws_instance.my_ec2]
}

# Step 7: Outputs
output "instance_id" {
  value       = aws_instance.my_ec2.id
  description = "The ID of the EC2 instance"
}

output "instance_public_ip" {
  value       = aws_eip.web_eip.public_ip
  description = "The Elastic IP of the EC2 instance"
}

