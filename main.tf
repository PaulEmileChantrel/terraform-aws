provider "aws" {
  region = "ca-central-1"
  access_key = ""
  secret_key = ""
}

resource "aws_vpc" "my_vpc"{
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "production_vpc"
  }
}


resource "aws_subnet" "subnet_1" {
  vpc_id = aws_vpc.my_vpc.id
  cidr_block = "10.0.0.0/24"
  tags = {
    Name = "production_subnet_1"
  }
}


resource "aws_instance" "app_server" {
  ami           = "ami-01a2cb0405fa1877b"
  instance_type = "t2.micro"
  tags = {
    Name = "Helloworld"
  }
}