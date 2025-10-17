# Step 1: Specify AWS provider
provider "aws" {
  region = "ap-south-1"   # Mumbai region
}

# Step 2: Create a security group for EC2
resource "aws_security_group" "web_sg" {
  name_prefix = "web-sg-new-"
  description = "Allow SSH and HTTP"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # SSH access
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # HTTP access
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "WebSecurityGroup"
  }

  lifecycle {
    create_before_destroy = true
  }
}

# Step 3: Create an EC2 instance
resource "aws_instance" "my_ec2" {
  ami                    = "ami-0f9708d1cd2cfee41"  # Replace with your AMI
  instance_type          = "t3.micro"
  key_name               = "sumanvi-key"            # Your key pair
  vpc_security_group_ids = [aws_security_group.web_sg.id]

  tags = {
    Name = "Sumanvi-EC2"
  }
}

# Step 4: Allocate Elastic IP and associate with EC2
resource "aws_eip" "web_eip" {
  instance   = aws_instance.my_ec2.id
  vpc        = true
  depends_on = [aws_instance.my_ec2]
}

# Step 5: Outputs
output "instance_id" {
  value       = aws_instance.my_ec2.id
  description = "The ID of the EC2 instance"
}

output "instance_public_ip" {
  value       = aws_eip.web_eip.public_ip
  description = "The Elastic IP of the EC2 instance"
}
