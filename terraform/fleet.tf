#################################################
# Create Fleet Security Group
#################################################
resource "aws_security_group" "fleetsg" {
  name = "Fleet Security Group"
  description = "Fleet Security Group"
  vpc_id = aws_vpc.VPC.id
  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }
  ingress {
    from_port = 443
    to_port = 443
    protocol = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }
  ingress {
    from_port = 1443
    to_port = 1443
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
# Deploy Fleet Sensor 
#################################################
resource "aws_instance" "fleet" {
  connection {
    user = "ec2-user"
  }
  tags = {
    Name = "fleet"
    Project = "${var.project}"
  }
  instance_type = "m5.large"
  ami = lookup(var.aws_amiv2, var.aws_region)
  key_name = var.key_name
  vpc_security_group_ids = ["${aws_security_group.fleetsg.id}"]
  subnet_id = aws_subnet.private1.id
}

#################################################
# Create EBS Volume for Fleet 
#################################################
resource "aws_ebs_volume" "fleetebs" {
  availability_zone = var.aws_az1
  size = 40
  type = "gp2"
  tags = {
    Name = "Fleet EBS Volume"
    Project = "${var.project}"
  }
}

#################################################
# Attach EBS Volume to Splunk Instance
#################################################
resource "aws_volume_attachment" "fleetebs_att" {
  device_name = "/dev/sdf"
  volume_id = aws_ebs_volume.fleetebs.id
  instance_id = aws_instance.fleet.id
}

