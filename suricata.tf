#provider information

provider "aws" { 
  region = "ap-southeast-2" 
   access_key = "access-key" 

  secret_key = "secret-key" 

  # access_key and secret_key are set as env_variables
}

# creating a VPC
resource "aws_vpc" "my_vpc" {
  cidr_block = "192.168.0.0/16"
}

# creating internet gateway to allow traffic to the internet
resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.my_vpc.id

  tags = {
    Name = "My_igw"
  }
}

# creating routing table to route traffic to the internet
resource "aws_route_table" "RT" {
  vpc_id = aws_vpc.my_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }
   route {
    cidr_block           = "192.168.157.0/24"

    network_interface_id = aws_network_interface.public_interface.id
  }

  tags = {
    Name = "Table"
  }
}

# creating a subnet inside our VPC
resource "aws_subnet" "subnet-one" {
  vpc_id     = aws_vpc.my_vpc.id
  cidr_block = "192.168.157.0/24"
  availability_zone = "ap-southeast-2a"
  tags = {
    Name = "Lab_subnet-1"
  }
}
resource "aws_subnet" "subnet-two" {
  vpc_id     = aws_vpc.my_vpc.id
  cidr_block = "192.168.158.0/24"
  availability_zone = "ap-southeast-2a"
  tags = {
    Name = "Lab_subnet-2"
  }
}

# creating network interfaces
# first interface which is internet facing
resource "aws_network_interface" "public_interface" {
  subnet_id       = aws_subnet.subnet-one.id
  private_ips     = ["192.168.157.10"]
  security_groups = [aws_security_group.allow_web.id]
}
# second interface which is internal facing
resource "aws_network_interface" "internal_interface" {
  subnet_id   = aws_subnet.subnet-two.id
  private_ips = ["192.168.158.10"]
  security_groups = [aws_security_group.allow_web.id]
}
resource "aws_network_interface" "machine-one" {
  subnet_id   = aws_subnet.subnet-two.id
  private_ips = ["192.168.158.20"]
  security_groups = [aws_security_group.allow_web.id]
}

# associating routetable with subnet
 resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.subnet-one.id
  route_table_id = aws_route_table.RT.id
 }
 # associating routetable with subnet
 resource "aws_route_table_association" "b" {
  subnet_id      = aws_subnet.subnet-two.id
  route_table_id = aws_route_table.RT.id
 }
  

 # defining the security group
 # security group
resource "aws_security_group" "allow_web" {
  name        = "allow_traffic"
  description = "Allow TLS inbound traffic"
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
  ingress {
    description      = "Thehive"
    from_port        = 9000
    to_port          = 9000
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }
    ingress {
    description = "ICMP (Ping)"
    from_port   = -1  # ICMP doesn't have ports, so use -1
    to_port     = -1  # ICMP doesn't have ports, so use -1
    protocol    = "icmp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  tags = {
    Name = "allow_web_traffic"
  }
}
resource "aws_security_group" "allow_ssh" {
  name        = "allow_ssh_traffic"
  description = "Allow ssh"
  vpc_id      = aws_vpc.my_vpc.id

  ingress {
    description      = "SSH"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  tags = {
    Name = "allow_ssh"
  }
}
# machine-1: Linux Gateway
resource "aws_instance" "gateway" {
   ami               = "ami-0d02292614a3b0df1"
   instance_type     = "t2.micro"
   availability_zone = "ap-southeast-2a"
   key_name          = "Lab-01"
   
   network_interface {
     device_index         = 0
     network_interface_id = aws_network_interface.public_interface.id
   }
   network_interface {
    device_index         = 1
    network_interface_id = aws_network_interface.internal_interface.id
  }
  tags = {
     Name = "Gate-way-10"
}
}
resource "aws_eip" "Gateway-1" {

  network_interface = aws_network_interface.public_interface.id
  domain = "vpc"
}
resource "aws_instance" "mach-one" {
   ami               = "ami-0d02292614a3b0df1"
   instance_type     = "t2.micro"
   availability_zone = "ap-southeast-2a"
   key_name          = "Lab-01"

   network_interface {
    device_index         = 0
    network_interface_id = aws_network_interface.machine-one.id
  }

  tags = {
    Name = "Machine-10"
  }
}
resource "aws_eip" "one" {
  instance = aws_instance.mach-one.id
  domain = "vpc"
}
