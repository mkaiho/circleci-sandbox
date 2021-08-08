variable "zone_name" {
  type = string
}

provider "aws" {
  region = "ap-northeast-1"
}

data "aws_route53_zone" "test_ip" {
  name = var.zone_name
}

resource "aws_vpc" "test_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true
}

resource "aws_internet_gateway" "test_igw" {
  vpc_id = aws_vpc.test_vpc.id

  tags = {
    "Name" = "test-igw"
  }
}

resource "aws_security_group" "test_sg" {
  vpc_id = aws_vpc.test_vpc.id
  name   = "test-sg"
  tags = {
    "Name" = "test-sg"
  }
}

resource "aws_security_group_rule" "test_sg_in_ssh" {
  security_group_id = aws_security_group.test_sg.id
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "test_sg_in_icmp" {
  security_group_id = aws_security_group.test_sg.id
  type              = "ingress"
  from_port         = -1
  to_port           = -1
  protocol          = "icmp"
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "test_sg_in_out" {
  security_group_id = aws_security_group.test_sg.id
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_subnet" "test_subnet_public-1a" {
  vpc_id                  = aws_vpc.test_vpc.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true

  availability_zone = "ap-northeast-1a"
  tags = {
    "Name" = "test_subnet_public_1a"
  }
}

resource "aws_route_table" "test_subnet_public-1a" {
  vpc_id = aws_vpc.test_vpc.id
  tags = {
    "Name" = "test-public-route-table"
  }
}

resource "aws_route_table_association" "test_subnet_public-1a" {
  subnet_id      = aws_subnet.test_subnet_public-1a.id
  route_table_id = aws_route_table.test_subnet_public-1a.id
}

resource "aws_route" "test_subnet_public-1a" {
  route_table_id         = aws_route_table.test_subnet_public-1a.id
  gateway_id             = aws_internet_gateway.test_igw.id
  destination_cidr_block = "0.0.0.0/0"
}

resource "aws_instance" "test" {
  subnet_id     = aws_subnet.test_subnet_public-1a.id
  ami           = "ami-09ebacdc178ae23b7"
  instance_type = "t2.micro"
  tags = {
    Name = "test"
  }
  vpc_security_group_ids = [
    aws_security_group.test_sg.id
  ]
  key_name = "my-ec2-key"
}

resource "aws_route53_record" "test_ip" {
  zone_id = data.aws_route53_zone.test_ip.zone_id
  name    = data.aws_route53_zone.test_ip.name
  type    = "A"
  ttl     = "300"
  records = [
    aws_instance.test.public_ip
  ]
  depends_on = [
    aws_instance.test
  ]
}

output "test_instance_id" {
  value = aws_instance.test.id
}
