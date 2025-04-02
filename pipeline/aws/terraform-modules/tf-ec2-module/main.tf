provider "aws" {
  region = var.region
}

resource "aws_vpc" "paula-vpc" {
  cidr_block = var.vpc_cidr
  tags       = merge(local.common_tags, { Name = "paula-vpc" })
}

resource "aws_subnet" "public-subnet" {
  vpc_id                  = aws_vpc.paula-vpc.id
  cidr_block              = var.public_subnet_cidr
  map_public_ip_on_launch = true
  availability_zone       = var.public_subnet_az
  tags                    = merge(local.common_tags, { Name = "public-subnet" })
}

resource "aws_subnet" "private-subnet" {
  vpc_id            = aws_vpc.paula-vpc.id
  cidr_block        = var.private_subnet_cidr
  availability_zone = var.private_subnet_az
  tags              = merge(local.common_tags, { Name = "private-subnet" })
}

resource "aws_internet_gateway" "net-igw" {
  vpc_id = aws_vpc.paula-vpc.id
  tags   = merge(local.common_tags, { Name = "net-igw" })
}

resource "aws_route_table" "public-rt" {
  vpc_id = aws_vpc.paula-vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.net-igw.id
  }
  tags = merge(local.common_tags, { Name = "public-rt" })
}

resource "aws_route_table_association" "public-rt" {
  subnet_id      = aws_subnet.public-subnet.id
  route_table_id = aws_route_table.public-rt.id
}

resource "aws_security_group" "paula-sg" {
  vpc_id = aws_vpc.paula-vpc.id
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description      = "SSH"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["86.120.230.117/32"]
    ipv6_cidr_blocks = ["::/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = merge(local.common_tags, { Name = "paula-sg" })
}
resource "aws_instance" "web" {
  ami                    = "ami-0e9085e60087ce171" # Ubuntu AMI
  instance_type          = "t2.micro"
  availability_zone      = var.public_subnet_az
  subnet_id = aws_subnet.public-subnet.id
  vpc_security_group_ids = [aws_security_group.paula-sg.id]
 
  tags = merge(local.common_tags, { Name = "WebServer" })

}

