# VPC
resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
  enable_dns_support = true
  enable_dns_hostnames = true
  tags = {
    Name = "${var.project_name}-Network"
  }
}

# Internet Gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "${var.project_name}-IGW"
  }
}

# Public Main Microservice Subnet
resource "aws_subnet" "public_main_microservice" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.11.0/24"
  availability_zone = "us-east-1a"
  map_public_ip_on_launch = true
  tags = {
    Name = "${var.project_name}-PublicSubnet-Main"
  }
}

# Route Table for Public Main Microservice
resource "aws_route_table" "public_main_microservice" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "10.0.0.0/16"
    gateway_id = "local"
  }
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
  tags = {
    Name = "${var.project_name}-PublicRouteTable"
  }
}

resource "aws_route_table_association" "public_main_microservice_association" {
  subnet_id      = aws_subnet.public_main_microservice.id
  route_table_id = aws_route_table.public_main_microservice.id
}

# Private Subnet for Report
resource "aws_subnet" "private_report" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.12.0/24"
  availability_zone = "us-east-1a"
  tags = {
    Name = "${var.project_name}-PrivateSubnet-Report"
  }
}

# Route Table for Private Subnet Report
resource "aws_route_table" "private_report" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "10.0.0.0/16"
    gateway_id = "local"
  }
  tags = {
    Name = "${var.project_name}-PrivateRouteTable-Report"
  }
}

resource "aws_route_table_association" "private_report_association" {
  subnet_id      = aws_subnet.private_report.id
  route_table_id = aws_route_table.private_report.id
}

# RDS1 Subnet
resource "aws_subnet" "rds1" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.13.0/24"
  availability_zone = "us-east-1a"
  tags = {
    Name = "${var.project_name}-DbSubnet-RDS1"
  }
}
# RDS2 Subnet
resource "aws_subnet" "rds2" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.15.0/24"
  availability_zone = "us-east-1b"
  tags = {
    Name = "${var.project_name}-DbSubnet-RDS2"
  }
}
# Route Table for RDS Subnet
resource "aws_route_table" "rds" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "10.0.0.0/16"
    gateway_id = "local"
  }
  tags = {
    Name = "${var.project_name}-RdsRouteTable"
  }
}

resource "aws_route_table_association" "rds1_association" {
  subnet_id      = aws_subnet.rds1.id
  route_table_id = aws_route_table.rds.id
}
resource "aws_route_table_association" "rds2_association" {
  subnet_id      = aws_subnet.rds2.id
  route_table_id = aws_route_table.rds.id
}
# Public Bastion Subnet
resource "aws_subnet" "public_bastion" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.14.0/24"
  availability_zone = "us-east-1b"
  map_public_ip_on_launch = true
  tags = {
    Name = "${var.project_name}-PublicSubnet-Bastion"
  }
}

# Route Table for Bastion
resource "aws_route_table" "public_bastion" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
  tags = {
    Name = "${var.project_name}-PublicRouteTableBastion"
  }
}

resource "aws_route_table_association" "public_bastion_association" {
  subnet_id      = aws_subnet.public_bastion.id
  route_table_id = aws_route_table.public_bastion.id
}

# Security Group for Bastion Host
resource "aws_security_group" "bastion" {
  vpc_id = aws_vpc.main.id

  ingress {
    from_port   = 22
    to_port     = 22
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
    Name = "${var.project_name}-BastionSG"
  }
}

# Security Group for Public Instance
resource "aws_security_group" "public_instance" {
  vpc_id = aws_vpc.main.id
  description = "Allow HTTP, HTTPS, and SSH traffic"

  ingress {
    from_port   = 8080
    to_port     = 8080
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
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port       = 3306  # MySQL port
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.rds_sg.id] 
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }


  tags = {
    Name = "${var.project_name}-PublicInstanceSG"
  }
}

# Security Group for Private Instances
resource "aws_security_group" "private_instances" {
  vpc_id = aws_vpc.main.id
  ingress {
    from_port       = 3306  # MySQL port
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.rds_sg.id] 
  }
  # ingress {
  #   from_port   = 22
  #   to_port     = 22
  #   protocol    = "tcp"
  #   cidr_blocks = ["0.0.0.0/0"]
  # }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-PrivateInstancesSG"
  }
}

# Security Group for Private Instance RDS
resource "aws_security_group" "rds_sg" {
  vpc_id = aws_vpc.main.id

  ingress {
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

  tags = {
    Name = "rds_security_group"
  }
}

# DB Main Subnet Group
resource "aws_db_subnet_group" "mainDb_sbg" {
  name       = "${var.project_name}-dbsubnet-rds"
  subnet_ids = [
    aws_subnet.rds1.id,
    aws_subnet.rds2.id
  ]

  tags = {
    Name = "${var.project_name}-dbsubnet-rds"
  }
}

# VPC Endpoints
resource "aws_vpc_endpoint" "sqs" {
  vpc_id              = aws_vpc.main.id
  service_name        = "com.amazonaws.us-east-1.sqs"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = [
    aws_subnet.public_main_microservice.id
  ]
  private_dns_enabled = true

  security_group_ids = [
    aws_security_group.public_instance.id
  ]

  tags = {
    Name = "${var.project_name}-VPC-SQS-Endpoint"
  }
}

resource "aws_vpc_endpoint" "dynamodb" {
  vpc_id            = aws_vpc.main.id
  service_name      = "com.amazonaws.us-east-1.dynamodb"
  vpc_endpoint_type = "Gateway"

  route_table_ids = [
    aws_route_table.private_report.id
  ]

  tags = {
    Name = "${var.project_name}-VPC-DynamoDB-Endpoint"
  }
}
