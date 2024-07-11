#!/bin/bash
set -e  # Terminar el script si ocurre un error

# Update Packages
echo "Updating packages..."
sudo yum update -y

# Install AWS CLI
echo "Installing AWS CLI..."
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install

# Set up AWS CLI 
echo "Configuring AWS CLI..."
aws configure set aws_access_key_id <ACCSES_KEY> --profile read-accessS3-profile
aws configure set aws_secret_access_key <SECRET_KEY> --profile read-accessS3-profile
aws configure set region us-east-1 --profile read-accessS3-profile
aws configure set output json --profile read-accessS3-profile

# Install Docker
echo "Installing Docker..."
sudo yum install -y docker
sudo service docker start
sudo usermod -a -G docker ec2-user

# Download Docker image from S3
echo "Downloading Docker image from S3..."
aws s3 cp s3://alejandromateus-bucket-task1/image-files/gym-service.tar ./image-files/gym-service.tar --profile read-accessS3-profile

# Download Env File from S3 for set up the container
echo "Downloading .env file from S3..."
aws s3 cp s3://alejandromateus-bucket-task1/envFiles/main/.env ./envFiles/.env --profile read-accessS3-profile

#Load docker image from ./image-files/gym-service.tar
echo "Loading docker image from ./image-files/gym-service.tar"
sudo docker load -i ./image-files/gym-service.tar

#Run a container of the image
echo "Run a container of the image"
sudo docker run -d --name gym-service --env-file ./envFiles/.env -p 8080:8080 gym-core-image:v1.0


# Install CloudWatch Agent
sudo yum install -y amazon-cloudwatch-agent
# Descargar la configuración de CloudWatch Agent desde S3
sudo aws s3 cp s3://alejandromateus-bucket-task1/cwagent-config.json /opt/aws/amazon-cloudwatch-agent/bin/config.json
# Iniciar el agente de CloudWatch
sudo /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl -a fetch-config -m ec2 -c file:/opt/aws/amazon-cloudwatch-agent/bin/config.json -s
               

echo "Setup script completed successfully."
