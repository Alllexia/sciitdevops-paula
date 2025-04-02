#################################
# Configurez backend pentru Terraform
#################################
terraform {
  backend "s3" {
    bucket         = "mariusb-tf-state"
    key            = "aws/deployment.tfstate"
    region         = "eu-west-1"
    encrypt        = true
  }
}

#################################
# Configurez provider AWS
#################################
provider "aws" {
  region = "eu-west-1"
}

#################################
# Creez VPC
#################################
resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

    tags = {
    Name = "k3s-vpc"
    Environment = "dev"
    Project     = "k3s-cluster"
  }
}

#################################
# Creez subnet publica
#################################
resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true
}

#################################
# Creez Internet Gateway
#################################
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id
}

#################################
# Creez Route Table
#################################
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
}

#################################
# Asociez route table cu subnetul public
#################################
resource "aws_route_table_association" "public_assoc" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

#################################
# Creez security group pentru acces SSH + HTTP/S
#################################
resource "aws_security_group" "ssh_access" {
  vpc_id = aws_vpc.main.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
  from_port   = 6443
  to_port     = 6443
  protocol    = "tcp"
  cidr_blocks = ["0.0.0.0/0"]
}

  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 1080
    to_port     = 1080
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

#################################
# Generez cheia SSH
#################################
resource "tls_private_key" "ssh" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

#################################
# Creez key pair AWS
#################################
resource "aws_key_pair" "deployer" {
  key_name   = "deployer-key"
  public_key = tls_private_key.ssh.public_key_openssh
}

#################################
# Stochez cheia privata in Secrets Manager
#################################
resource "aws_secretsmanager_secret" "ssh_key" {
  name = "deployer-key"
  recovery_window_in_days = 0
}

resource "aws_secretsmanager_secret_version" "ssh_key_value" {
  secret_id     = aws_secretsmanager_secret.ssh_key.id
  secret_string = tls_private_key.ssh.private_key_pem
}

#################################
# Creez instanta master si instalez K3s
#################################
resource "aws_instance" "master" {
  ami                    = "ami-01213ad3f03c4733c"
  instance_type          = "t3.medium"
  subnet_id              = aws_subnet.public.id
  vpc_security_group_ids = [aws_security_group.ssh_access.id]
  key_name               = aws_key_pair.deployer.key_name

  tags = {
    Name = "master"
  }
}

#################################
# Creez instanta web (placeholder)
#################################
resource "aws_instance" "web" {
  ami                    = "ami-01213ad3f03c4733c"
  instance_type          = "t2.micro"
  subnet_id              = aws_subnet.public.id
  vpc_security_group_ids = [aws_security_group.ssh_access.id]
  key_name               = aws_key_pair.deployer.key_name


  tags = {
    Name = "web"
  }
}

#################################
# Stochez IP-urile in SSM Parameter Store
#################################
resource "aws_ssm_parameter" "master_ip" {
  name  = "/k3s/master_ip"
  type  = "String"
  value = aws_instance.master.public_ip
}

resource "aws_ssm_parameter" "web_ip" {
  name  = "/k3s/web_ip"
  type  = "String"
  value = aws_instance.web.public_ip
}
