provider "aws" {
  region = "ca-central-1"
  access_key = ""
  secret_key = ""
}

variable "subnet_prefix" {
  type        = string
  #default     = ""
  description = "cidr block for the subnet"
}


# 1. Creat VPC
resource "aws_vpc" "my_vpc"{
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "production_vpc"
  }
}




# 2. Create Internet Gateway

resource "aws_internet_gateway" "gw"{
  vpc_id = aws_vpc.my_vpc.id
}

# 3. Create Custom Route Table
resource "aws_route_table" "prod_route_table" {
  vpc_id = aws_vpc.my_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }

  route {
    ipv6_cidr_block        = "::/0"
    gateway_id = aws_internet_gateway.gw.id
  }

  tags = {
    Name = "prod_route_table"
  }
}

# 4. Create Subnet
resource "aws_subnet" "subnet_1" {
  vpc_id = aws_vpc.my_vpc.id
  cidr_block = var.subnet_prefix#"10.0.1.0/24"
  availability_zone = "ca-central-1a"
  tags = {
    Name = "production_subnet_1"
  }
}

# 5. Associate subnet with route table
resource "aws_route_table_association" "a"{
  subnet_id = aws_subnet.subnet_1.id
  route_table_id = aws_route_table.prod_route_table.id
}

# 6. Security Group Policy to allow port 22,80,443
resource "aws_security_group" "allow_web" {
  name        = "allow_web"
  description = "Allow web traffic"
  vpc_id      = aws_vpc.my_vpc.id

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
    Name = "allow_tls"
  }
}

# 7. Create Network Interface with an IP in the subnet

resource "aws_network_interface" "test" {
  subnet_id       = aws_subnet.subnet_1.id
  private_ips     = ["10.0.1.50"]
  security_groups = [aws_security_group.allow_web.id]
}

# 8. Assign an EIP to the NI
resource "aws_eip" "one" {
  domain                    = "vpc"
  network_interface         = aws_network_interface.test.id
  associate_with_private_ip = "10.0.1.50"
  depends_on = [aws_internet_gateway.gw]
}


output "server_public_ip"{
  value = aws_eip.one.public_ip
}
# 9. Create Ubuntu EC2
resource "aws_instance" "app_server" {
  ami           = "ami-01a2cb0405fa1877b"
  instance_type = "t2.micro"
  availability_zone = "ca-central-1a"
  #key_name = "main-key"

  network_interface {
    device_index = 0
    network_interface_id = aws_network_interface.test.id
  }

  tags = {
    Name = "web-server"
  }
  user_data = <<-EOF
                #!/bin/bash
                sudo apt update -y
                sudo apt install apache2 -y
                sudo systemctl start apache2
                sudo bash -c 'echo your webserver > /var/www/html/index.html'
                EOF
}

output "server_private_ip"{
  value = aws_instance.app_server.private_ip
}

output "server_id"{
  value = aws_instance.app_server.id
}