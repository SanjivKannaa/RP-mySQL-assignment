provider "aws" {
  region = "ap-south-1" # Change if needed
}

# Get default VPC
data "aws_vpc" "default" {
  default = true
}

# Get default subnets
data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

# Security Group with SSH + MySQL
resource "aws_security_group" "mysql_sg" {
  name        = "mysql_sg"
  description = "Allow SSH and MySQL"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "MySQL"
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# EC2 Instance
resource "aws_instance" "mysql_1" {
  ami           = "ami-0b5317ee10bd261f7" # Debian 13
  instance_type = "t2.micro"
  subnet_id     = element(data.aws_subnets.default.ids, 0)
  vpc_security_group_ids = [aws_security_group.mysql_sg.id]
  key_name      = "RP"  # Use your existing key pair

  tags = {
    Name = "mysql-instance-1"
  }
}

resource "aws_instance" "mysql_2" {
  ami           = "ami-0b5317ee10bd261f7" # Debian 13
  instance_type = "t2.micro"
  subnet_id     = element(data.aws_subnets.default.ids, 0)
  vpc_security_group_ids = [aws_security_group.mysql_sg.id]
  key_name      = "RP"  # Use your existing key pair

  tags = {
    Name = "mysql-instance-2"
  }
}

# Output Public IP
output "mysql1_public_ip" {
  value = aws_instance.mysql_1.public_ip
}

output "mysql2_public_ip" {
  value = aws_instance.mysql_2.public_ip
}
