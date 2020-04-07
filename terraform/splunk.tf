#################################################
# Create Splunk Security Group
#################################################
resource "aws_security_group" "splunksg" {
  name = "Splunk Security Group"
  description = "Splunk Security Group"
  vpc_id = aws_vpc.VPC.id
  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }
  ingress {
    from_port = 8000
    to_port = 8000
    protocol = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }
  ingress {
    from_port = 8089
    to_port = 8089
    protocol = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }
  ingress {
    from_port = 9997
    to_port = 9997
    protocol = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }
  ingress {
    from_port = 8080
    to_port = 8080
    protocol = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }
  ingress {
    from_port = 514
    to_port = 514
    protocol = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }
  egress {
    from_port = 0
    to_port = 0
    protocol = -1
    cidr_blocks = ["0.0.0.0/0"]
  }
}

#################################################
# Deploy Small Splunk Demo System
#################################################
resource "aws_instance" "splunk" {
  connection {
    user = "ec2-user"
  }
  tags = {
    Name = "splunk"
    Name1 = "phantom"
    Project = "${var.project}"
  }
  instance_type = "m5.large"
  ami = lookup(var.aws_amiv2, var.aws_region)
  key_name = var.key_name
  vpc_security_group_ids = ["${aws_security_group.splunksg.id}"]
  subnet_id = aws_subnet.private1.id
  root_block_device {
    volume_size = "100"
  }
}
