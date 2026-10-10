provider "aws" {
  region = var.region
}

# Creating our vpc
resource "aws_vpc" "myapp_vpc" {
  cidr_block = var.vpc_cidr_block
  tags = {
    Name = "${ var.env_prefix }-vpc"
  }
}

# Creating subnet for our vpc
resource "aws_subnet" "myapp_subnet-1" {
  vpc_id            = aws_vpc.myapp_vpc.id
  cidr_block        = var.subnet_cidr_block
  availability_zone = var.availability_zone
  tags = {
    Name = "${ var.env_prefix }-subnet-1"
  }
}


# creating Internet Gate-Way
resource "aws_internet_gateway" "myapp_igw" {
  vpc_id = aws_vpc.myapp_vpc.id
  tags = {
    Name = "${ var.env_prefix }-internet-gateway"
  }
}
/*
# Creating a new router table
resource "aws_route_table" "myapp_route_table" {
  vpc_id = aws_vpc.myapp_vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.myapp_igw.id
  }
  tags = {
    Name = "${ var.env_prefix }-route-table"
  }
}

# associate our subnet to our route table
resource "aws_route_table_association" "myapp_route_table_association" {
  subnet_id      = aws_subnet.myapp_subnet-1.id
  route_table_id = aws_route_table.myapp_route_table.id
}*/

# using default rout table created while creating the vpc
resource "aws_default_route_table" "main-route-table" {
  default_route_table_id = aws_vpc.myapp_vpc.default_route_table_id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.myapp_igw.id
  }
  tags = {
    Name = "${ var.env_prefix }-main-route-table"
  }
}

# associate our subnet to our route table
resource "aws_route_table_association" "myapp_route_table_association" {
  subnet_id      = aws_subnet.myapp_subnet-1.id
  route_table_id = aws_default_route_table.main-route-table.id
}
/*
# Creating a new Security Group
resource "aws_security_group" "myapp_sg" {
  name        = "${var.env_prefix}-myapp-sg"
  description = "Security group for myapp"
  vpc_id      = aws_vpc.myapp_vpc.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.my_ip]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.env_prefix}-myapp-sg"
  }
}*/

# using default security group created while creating the vpc
# The difference between creating a new sg and using the existing default one is the resource name
resource "aws_default_security_group" "default_sg" {
  vpc_id      = aws_vpc.myapp_vpc.id

  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.my_ip, var.jenkins_ip]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.env_prefix}-default-sg"
  }
}

data "aws_ami" "latest-amazon-linux-image" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name = "name"
    values = ["al2023-ami-*-kernel-6.18-x86_64"]
  }
  filter {
    name = "virtualization-type"
    values = ["hvm"]
  }
}

# Creating EC2 Server Instance
resource "aws_instance" "myapp_server" {
  ami           = data.aws_ami.latest-amazon-linux-image.id
  instance_type = var.instance_type
  subnet_id     = aws_subnet.myapp_subnet-1.id
  vpc_security_group_ids = [aws_default_security_group.default_sg.id]
  availability_zone = var.availability_zone

  associate_public_ip_address = true
  key_name = var.ssh-key-name

  user_data = file(var.user_data_script_location)

  # make sure server is clean when we destroy and create new server
  user_data_replace_on_change = true

  root_block_device {
    volume_type           = "gp3"
    volume_size           = 20
    encrypted             = true
    delete_on_termination = true
  }

  tags = {
    Name = "${var.env_prefix}-server"
  }

}
