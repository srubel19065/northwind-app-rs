provider "aws" {
  region = var.region
}

resource "aws_security_group" "app_security_group" {
  name = var.sg_name

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
    from_port   = 5000
    to_port     = 5000
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

resource "aws_security_group" "db_security_group" {
  name = var.db_sg_name

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

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
}

resource "aws_instance" "db_instance" {
  tags = {
    Name = var.db_name
  }
  ami                         = var.db_ami_id
  instance_type               = var.instance_type
  associate_public_ip_address = true
  key_name                    = var.key_name
  vpc_security_group_ids      = [aws_security_group.db_security_group.id]
}

resource "aws_instance" "app_instance" {
  tags = {
    Name = var.app_name
  }
  ami                         = var.ami_id
  instance_type               = var.instance_type
  associate_public_ip_address = true
  key_name                    = var.key_name
  vpc_security_group_ids      = [aws_security_group.app_security_group.id]

  user_data = <<-EOF
              #!/bin/bash
              export DB_CONNECTION_URI=mysql+pymysql://admin:password@${aws_instance.db_instance.private_ip}:3306/northwind

              sudo apt update -y
              sudo apt install nginx -y
              sudo sed -i "s|try_files .*;|proxy_pass http://127.0.0.1:5000;|g" /etc/nginx/sites-available/default
              sudo systemctl restart nginx
              sudo systemctl enable nginx

              echo "export DB_CONNECTION_URI=mysql+pymysql://admin:password@${aws_instance.db_instance.private_ip}:3306/northwind" | sudo tee -a /etc/profile.d/db_connection_uri.sh

              sudo chmod +x /etc/profile.d/db_connection_uri.sh

              cd /repo/app
              waitress-serve --port=5000 northwind_web:app > waitress.log 2>&1 &
              EOF
}
