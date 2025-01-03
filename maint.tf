provider "aws" {
  region = "us-east-2"  # Specify your AWS region
}


resource "aws_vpc" "lamar_TF_VPC" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "LamarVPC_TF"
  }
}


# Create Security Group
resource "aws_security_group" "lamar_react_sg" {
  name        = "lamar-POK-sg"
  description = "Allow inbound traffic for Lamar React app"


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
    from_port   = 3000
    to_port     = 3000
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

# Create Ubuntu EC2 Instance
resource "aws_instance" "lamar_react_instance" {
  ami           = "ami-036841078a4b68e14"  # Replace with the correct Ubuntu AMI ID
  instance_type = "t2.micro"
  key_name      = "mariaDB_server_key"  # Replace with your key pair name

  security_groups = [aws_security_group.lamar_react_sg.name]

  user_data = <<-EOF
              #!/bin/bash

              # Update the system
              sudo apt update -y
              sudo apt upgrade -y


              # SECTION 2: Apache server setup
              sudo apt install -y apache2
              TOKEN=`curl -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600"` \
              && PUBLIC_IP=`curl -H "X-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/latest/meta-data/public-ipv4`
              sudo chmod -R 777 /var/www/html
              echo "<html>
              <body>
                  <p>Public IP address of this instance is <b>$PUBLIC_IP</b></p>
              </body>
              </html>" > /var/www/html/index.html
              sudo systemctl start apache2
              sudo systemctl enable apache2



              # SECTION 1: React app setup
              sudo apt install -y git curl
              sudo apt update -y
              sudo apt install -y git
              curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
              sudo apt install -y nodejs
              git clone https://github.com/mikhail-w/pokedex.git /home/ubuntu/react-app
              cd /home/ubuntu/react-app
              sudo apt install npm
              npm install -g vite
              npm run dev -- --host port 5000 &
              EOF

  tags = {
    Name = "PKR-AppInstance"
  }
}

# Output EC2 instance public IP
output "lamar_public_ip" {
  value = aws_instance.lamar_react_instance.public_ip
}