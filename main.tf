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

# DB Instance Main Microservice
resource "aws_db_instance" "db_main_microservice" {
  allocated_storage       = 20 
  max_allocated_storage   = 100 
  identifier              = "db-gym-main-service"
  db_name                 = "db_gym_main_service"
  engine                  = "mysql"
  engine_version          = "8.0.35"
  instance_class          = "db.t3.micro"
  username                = "admin"
  password                = "prodDb2024"
  storage_type            = "gp2"
  skip_final_snapshot     = true
  publicly_accessible     = false
  db_subnet_group_name    = aws_db_subnet_group.mainDb_sbg.name
  vpc_security_group_ids  = [aws_security_group.rds_sg.id]
}

# DB Instance Report Microservice
resource "aws_db_instance" "db_report_microservice" {
  allocated_storage       = 20 
  max_allocated_storage   = 100 
  identifier              = "db-gym-report-service"
  db_name                 = "db_gym_report_service"
  engine                  = "mysql"
  engine_version          = "8.0.35"
  instance_class          = "db.t3.micro"
  username                = "admin"
  password                = "prodDb2024"
  storage_type            = "gp2"
  skip_final_snapshot     = true
  publicly_accessible     = false
  db_subnet_group_name    = aws_db_subnet_group.mainDb_sbg.name
  vpc_security_group_ids  = [aws_security_group.rds_sg.id]
}


#Resource to create SQS queues
resource "aws_sqs_queue" "queues" {
  for_each = var.queues

  name       = each.value
  fifo_queue = true
  content_based_deduplication = true
}

resource "aws_sqs_queue_policy" "queues_policy" {
  for_each = aws_sqs_queue.queues

  queue_url = each.value.id
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          AWS = "arn:aws:iam::938282813707:user/FullAccess_UserSQS"
        },
        Action = "sqs:*",
        Resource = each.value.arn,
        Condition = {
          ArnEquals = {
            "aws:SourceArn" = aws_vpc_endpoint.sqs.arn
          }
        }
      },
      #Rule for test in dev enviroment
      {
        Effect = "Allow",
        Principal = {
          AWS = "arn:aws:iam::938282813707:user/FullAccess_UserSQS"
        },
        Action = "sqs:*",                  
        Resource = each.value.arn,
        Condition = {
          IpAddress = {
            "aws:SourceIp" = "0.0.0.0/0"
          }
        }
      }
    ]
  })
}

#Base EC2 Instance for AMI

resource "aws_instance" "base-main_microservice" {
  ami           = "ami-06c68f701d8090592"
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.public_main_microservice.id
  key_name      = "gym-core-service-keypair"

  security_groups = [
    aws_security_group.public_instance.id,
  ]
  user_data = file("./setup_script_mainEC2.sh")
  tags = {
    Name = "${var.project_name}-BaseMainMicroservice"
  }
}

resource "aws_instance" "base-report_microservice" {
  ami           = "ami-06c68f701d8090592"
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.public_main_microservice.id
  key_name      = "gym-report-keypair"

  security_groups = [
    aws_security_group.private_instances.id
  ]
  user_data = file("./setup_script_reportEC2.sh")
  tags = {
    Name = "${var.project_name}-BaseReportMicroservice"
  }
}

# EC2 Instances

# Bastion Host
resource "aws_instance" "bastion" {
  ami           = "ami-06c68f701d8090592"  # Amazon Linux 2 AMI
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.public_bastion.id
  key_name      = "gym-bastion-service-keypair" 

  security_groups = [
    aws_security_group.bastion.id,
  ]

  tags = {
    Name = "${var.project_name}-BastionHost"
  }
}

# Main Microservice Host
resource "aws_instance" "main_microservice" {
  ami           = "ami-055f597ad80eb85b8"
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.public_main_microservice.id
  key_name      = "gym-core-service-keypair"

  security_groups = [
    aws_security_group.public_instance.id,
  ]
  tags = {
    Name = "${var.project_name}-MainMicroservice"
  }
}

# Report Microservice Host
resource "aws_instance" "report_microservice" {
  ami           = "ami-0c55b159cbfafe1f0"
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.private_report.id
  key_name      = "gym-report-keypair"

  security_groups = [
    aws_security_group.private_instances.id,
  ]

  tags = {
    Name = "${var.project_name}-ReportMicroservice"
  }
}

#DinamoDB resource
resource "aws_dynamodb_table" "trainers_summary" {
  name           = "Trainers_Summary"
  billing_mode   = "PROVISIONED" # or "PAY_PER_REQUEST" for on-demand mode
  read_capacity  = 5
  write_capacity = 5

  hash_key = "TrainerUsername"
  range_key = "TrainerStatus"

  attribute {
    name = "TrainerUsername"
    type = "S"
  }

  attribute {
    name = "TrainerStatus"
    type = "S"
  }

  attribute {
    name = "TrainerFirstName"
    type = "S"
  }

  attribute {
    name = "TrainerLastName"
    type = "S"
  }

  global_secondary_index {
    name               = "TrainerName-Index"
    hash_key           = "TrainerFirstName"
    range_key          = "TrainerLastName"
    projection_type    = "ALL"
    read_capacity      = 5
    write_capacity     = 5
  }
  
  tags = {
    Name        = "Trainers"
    Environment = "Prod"
  }
}
resource "null_resource" "dynamodb_initial_data" {
  provisioner "local-exec" {
    command = <<EOT
      aws dynamodb put-item \
        --table-name ${aws_dynamodb_table.trainers_summary.name} \
        --item '{
          "TrainerUsername": {"S": "john.doe"},
          "TrainerStatus": {"S": "true"},
          "TrainerFirstName": {"S": "John"},
          "TrainerLastName": {"S": "Doe"},
          "YearList": {"M": {
            "2021": {"M": {
                "January": {"N": "10"},
                "February": {"N": "15"}
            }},
            "2022": {"M": {
                "March": {"N": "20"},
                "April": {"N": "25"}
            }}
          }}
        }'
    EOT
  }
  depends_on = [aws_dynamodb_table.trainers_summary]
}


output "dynamodb_table_name" {
  value = aws_dynamodb_table.trainers_summary.name
}

#Lambda resource

resource "null_resource" "lambda_zip" {
  provisioner "local-exec" {
    command = <<EOT
      zip ./lambda.zip ./report_lambda.py
    EOT
  }

  triggers = {
    lambda_source = filemd5("./report_lambda.py")
  }
}

resource "aws_lambda_function" "csv_report" {
  function_name = "${var.project_name}-CSV-Report"
  role          = "arn:aws:iam::938282813707:role/FullAccessRoleLamdaS3-DynamoDB"
  handler       = "report_lambda.lambda_handler"
  runtime       = "python3.8"
  filename      = "lambda.zip"

  timeout       = 100
  source_code_hash = filebase64sha256("./lambda.zip")
  environment {
    variables = {
      DYNAMODB_TABLE = aws_dynamodb_table.trainers_summary.name
      S3_BUCKET      = "alejandromateus-bucket-task1"
    }
  }

  depends_on = [null_resource.lambda_zip]
}

