provider "aws" {
  region = "ap-southeast-1"
}

resource "aws_vpc" "khanhtc_vpc" {
  cidr_block = "10.0.0.0/16"
  tags       = {
    Name = "khanhtc_vpc"
  }
}

resource "aws_internet_gateway" "khanhtc_igw" {
  vpc_id = aws_vpc.khanhtc_vpc.id

  tags = {
    Name = "khanhtc_igw"
  }
}

resource "aws_route_table" "khanhtc_vpc_route_table" {
  vpc_id = aws_vpc.khanhtc_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.khanhtc_igw.id
  }

  tags = {
    Name = "khanhtc_vpc_route_table"
  }
}

resource "aws_subnet" "khanhtc_vpc_public_subnet" {
  vpc_id     = aws_vpc.khanhtc_vpc.id
  cidr_block = "10.0.1.0/24"

  map_public_ip_on_launch = true

  tags = {
    Name = "khanhtc_vpc_public_subnet"
  }
}

resource "aws_route_table_association" "public" {
  route_table_id = aws_route_table.khanhtc_vpc_route_table.id
  subnet_id      = aws_subnet.khanhtc_vpc_public_subnet.id
}

resource "aws_security_group" "khanhtc_vpc_security_group" {
  vpc_id = aws_vpc.khanhtc_vpc.id

  #SSH
  ingress {
    from_port   = 22
    protocol    = "tcp"
    to_port     = 22
    cidr_blocks = ["0.0.0.0/0"]
  }

  #Internet
  ingress {
    from_port   = 3000
    protocol    = "tcp"
    to_port     = 3000
    cidr_blocks = ["0.0.0.0/0"]
  }

  #Outbound
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1" # Cho phép tất cả
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "khanhtc_vpc_security_group"
  }
}

resource "aws_instance" "khanhtc_vpc_ec2" {
  ami                    = "ami-0b5a4445ada4a59b1"
  instance_type          = "t2.micro"
  subnet_id              = aws_subnet.khanhtc_vpc_public_subnet.id
  key_name               = "khanhtc-vpc-keypair"
  vpc_security_group_ids = [aws_security_group.khanhtc_vpc_security_group.id]

  user_data = templatefile("${path.module}/user-data.sh", {git_repo_url = var.git_repo })

  tags = {
    Name = "khanhtc_vpc_ec2"
  }
}

output "khanhtc_resources" {
  value = {
    vpc_id            = aws_vpc.khanhtc_vpc.id
    subnet_id         = aws_subnet.khanhtc_vpc_public_subnet.id
    security_group_id = aws_security_group.khanhtc_vpc_security_group.id
    ec2_public        = aws_instance.khanhtc_vpc_ec2.public_ip
  }
}
