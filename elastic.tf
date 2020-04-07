#################################################
# Create Elastic/Kibana Security Group
#################################################
resource "aws_security_group" "elasticsg" {
  name = "Elastic"
  description = "elastic"
  vpc_id = aws_vpc.VPC.id
  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }
  ingress {
    from_port = 5601
    to_port = 5601
    protocol = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }
  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

#################################################
# Deploy an Elastic Search System
#################################################
resource "aws_instance" "elastic" {
  connection {
    user = "ec2-user"
  }
  tags = {
    Name = "elastic"
    Project = "${var.project}"
  }
  instance_type = "r5.large"
  ami = lookup(var.aws_amiv2, var.aws_region)
  key_name = var.key_name
  vpc_security_group_ids = ["${aws_security_group.elasticsg.id}"]
  subnet_id = aws_subnet.private1.id
  root_block_device {
    volume_size = "100"
  }
}


