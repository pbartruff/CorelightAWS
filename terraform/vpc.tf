##################################################
# Info for AWS
#################################################
# Access, Region, Zone, ETC. Info
provider "aws" {
  access_key = var.access_key
  secret_key = var.secret_key
  region     = var.aws_region
}
#################################################
# Create a Single AZ VPC with Public and Private
# subnets.  Bastions are included in the Public
# subnet using 1 Launch Configuration and 1 Auto
# scaling group.
#################################################

#################################################
# Create VPC
#################################################
resource "aws_vpc" "VPC" {
	cidr_block = var.vpc_cidr
	enable_dns_support = true
	enable_dns_hostnames = true
	tags = {
		Name = "${var.project}-VPC"
    Project = "${var.project}"
	}
}

#################################################
# Create Public Subnets
#################################################
resource "aws_subnet" "public1" {
	vpc_id = aws_vpc.VPC.id
	cidr_block = var.pub1_cidr
	map_public_ip_on_launch = true
	availability_zone = var.aws_az1
	tags = {
		Name = "Public 1 Subnet"
    Project = "${var.project}"
	}
}

#################################################
# Create Private Subnets
#################################################
resource "aws_subnet" "private1" {
	vpc_id = aws_vpc.VPC.id
	cidr_block = var.priv1_cidr
	availability_zone = var.aws_az1
	tags = {
		Name = "Private 1 Subnet"
    Project = "${var.project}"
	}
}

#################################################
# Create Internet Gateway
#################################################
resource "aws_internet_gateway" "igw" {
	vpc_id = aws_vpc.VPC.id
	tags = {
		Name = "${var.project}-IGW"
    Project = "${var.project}"
	}
}

#################################################
# Create an Elastic IP in each public subnet to support
# a NAT gateway in each AZ
#################################################
resource "aws_eip" "eip1" {
	vpc = true
	depends_on = [aws_internet_gateway.igw]
}

#################################################
# Create a NAT Gateway in each public subnet
#################################################
resource "aws_nat_gateway" "nat1" {
	allocation_id = aws_eip.eip1.id
	subnet_id = aws_subnet.public1.id
	depends_on = [aws_internet_gateway.igw]
}

#################################################
# Create Public and Private route tables
# to NAT Gateway
#################################################
resource "aws_route_table" "public" {
	vpc_id = aws_vpc.VPC.id
	tags = {
		Name = "Public Subnet Route Table"
    Project = "${var.project}"
	}
	route {
		cidr_block = "0.0.0.0/0"
		gateway_id = aws_internet_gateway.igw.id
	}
}
resource "aws_route_table" "private1" {
	vpc_id = aws_vpc.VPC.id
	tags = {
		Name = "Private1 Subnet Route Table"
    Project = "${var.project}"
	}
	route {
		cidr_block = "0.0.0.0/0"
		nat_gateway_id = aws_nat_gateway.nat1.id
	}
}

#################################################
# Associate Public subnets with route tables
#################################################
resource "aws_route_table_association" "pub1" {
	subnet_id = aws_subnet.public1.id
	route_table_id = aws_route_table.public.id
}

#################################################
# Associate Private subnets with route tables
#################################################
resource "aws_route_table_association" "priv1" {
	subnet_id = aws_subnet.private1.id
	route_table_id = aws_route_table.private1.id
}

#################################################
# Create Bastion Security Groups
#################################################
resource "aws_security_group" "bastion" {
  name = "bastion"
  description = "Bastion SG"
  vpc_id = aws_vpc.VPC.id
  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

#################################################
# Create Bastion launch configuration
#################################################
resource "aws_launch_configuration" "bastionlaunch" {
  image_id = lookup(var.aws_amiv2, var.aws_region)
  instance_type = "t2.micro"
  security_groups = ["${aws_security_group.bastion.id}"]
  key_name = var.key_name
  user_data = <<-EOF
        #!/bin/bash
        sudo yum -y update
        EOF
  lifecycle {
    create_before_destroy = true
  }
}

#################################################
# Create Bastion Auto Scaling Groups
#################################################
resource "aws_autoscaling_group" "asg1" {
  launch_configuration = aws_launch_configuration.bastionlaunch.id
  vpc_zone_identifier = ["${aws_subnet.public1.id}"]
  min_size = 1
  max_size = 1
  tag {
    key = "Name"
    value = "bastion1"
    propagate_at_launch = true
  }
  tag {
    key = "Project"
    value = var.project
    propagate_at_launch = true
  }
}
