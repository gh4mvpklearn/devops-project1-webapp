#test1
terraform {
  required_version = ">=0.12.13"
  backend "s3" {
    bucket         = "my-s3-state-bucket-2022"
    key            = "terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "aws-locks"
    encrypt        = true
  }
}
provider "aws" {
    region = var.aws-region
    #access_key = var.access_key
    #secret_key = var.secret_key
}

resource "aws_vpc" "prod-vpc" {
    cidr_block = var.vpc-cidr-block
}

resource "aws_internet_gateway" "prod-igw" {
    vpc_id = aws_vpc.prod-vpc.id
}

resource "aws_route_table" "prod-rt" {
    vpc_id = aws_vpc.prod-vpc.id

    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.prod-igw.id
    }

}
resource "aws_subnet" "prod-subnet" {
    vpc_id = aws_vpc.prod-vpc.id
    cidr_block = "10.0.1.0/24"
    availability_zone = "us-east-1a"
}

resource "aws_route_table_association" "prod-rt-ass" {
    subnet_id = aws_subnet.prod-subnet.id
    route_table_id = aws_route_table.prod-rt.id
}

resource "aws_security_group" "prod-sg" {
    name        = "allow_web"
  description = "Allow web traffic"
  vpc_id      = aws_vpc.prod-vpc.id

  ingress {
    description      = "HTTPS"
    from_port        = 443
    to_port          = 443
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    
  }

  ingress {
    description      = "HTTP"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    
  }
  
  ingress {
    description      = "SSH"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    
  }
  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "allow_web"
  }
}

resource "aws_network_interface" "nwif" {
    subnet_id = aws_subnet.prod-subnet.id
    private_ips = ["10.0.1.50"]
    security_groups = [aws_security_group.prod-sg.id]
}

resource "aws_eip" "prod-eip" {
    vpc = true
    network_interface = aws_network_interface.nwif.id
    associate_with_private_ip = "10.0.1.50"
    depends_on = [
      aws_internet_gateway.prod-igw
    ]
}

resource "aws_instance" "my-prod-web-server1" {
    ami = "ami-052efd3df9dad4825"
    instance_type = var.instance_type
    network_interface {
    network_interface_id = aws_network_interface.nwif.id
    device_index         = 0
  }
    user_data = <<-EOF
                #!/bin/bash
                sudo apt-get update -y
                sudo apt-get install -y apache2
                sudo systemctl start apache2.service
                sudo bash -c 'echo My very first web server :) > /var/www/html/index.html'
                EOF
  tags = {
    Name = "prod-server"
  }
}