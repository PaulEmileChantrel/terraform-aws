provider "aws" {
  region = "ca-central-1"
  access_key = ""
  secret_key = ""
}

resource "aws_instance" "app_server" {
  ami           = "ami-01a2cb0405fa1877b"
  instance_type = "t2.micro"
  tags = {
    Name = "Helloworld"
  }
}