#################################################
# Create Sensor Management and Monitoring
# Security Groups
#################################################
resource "aws_security_group" "sensor_mgmt" {
  name = "mgmt"
  description = "Management Interface Security Group"
  vpc_id = aws_vpc.VPC.id
  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }
  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port = 443
    to_port = 443
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

resource "aws_security_group" "sensor_mon" {
  name = "monitor"
  description = "Monitor Interface Security Group"
  vpc_id = aws_vpc.VPC.id
  #This really should be just from the mirror loadbalancer
  ingress {
    from_port = 4789
    to_port = 4789
    protocol = "udp"
    cidr_blocks = ["10.0.0.0/16"]
  }
  #Data should never leave the monitor interface so this may need tighter rules
  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

#################################################
# Create Network interfaces
#################################################
resource "aws_network_interface" "management" {
  subnet_id = aws_subnet.private1.id
  security_groups = ["${aws_security_group.sensor_mgmt.id}"]
  tags = {
    Name = "Sensor Management Interface"
    Project = "${var.project}"
  }
}
resource "aws_network_interface" "monitor" {
  subnet_id = aws_subnet.public1.id
  security_groups = ["${aws_security_group.sensor_mon.id}"]
  tags = {
    Name = "Sensor Monitor Interface"
    Project = "${var.project}"
  }
}

#################################################
# Deploy Corelight Sensor
#################################################
resource "aws_instance" "cl_sensor1" {
  instance_type = "m5.large"
  key_name = var.key_name
  ami = var.v18
  #Validate the damn interface indexes with documentation
  network_interface {
    network_interface_id = aws_network_interface.monitor.id
    device_index = 0
  }
  network_interface {
    network_interface_id = aws_network_interface.management.id
    device_index = 1
  }
  user_data = var.customer_id
  tags = {
    Name = "cl_sensor"
    Project = "${var.project}"
  }
}

#################################################
# Create Mirror Network Load Balancer
#################################################
resource "aws_lb" "mirrorlb" {
  name = "MirrorLB"
  load_balancer_type = "network"
  internal = true
  subnets = [
    "${aws_subnet.public1.id}",
  ]
  #enable_deletion_protection = False
  tags = {
    Name = "ELB for mirror target"
    Project = "${var.project}"
  }
}

#################################################
# Create Load Balancer Target Group
#################################################
resource "aws_lb_target_group" "lb_targetgroup" {
  name = "LBTargetGroup"
  port = "4789"
  protocol = "UDP"
	vpc_id = aws_vpc.VPC.id
  target_type = "instance"
}

#################################################
# Create Load Balancer Listener
#################################################
resource "aws_lb_listener" "lb_listener" {
  load_balancer_arn = aws_lb.mirrorlb.arn
  port = "4789"
  protocol = "UDP"
  default_action {
    type = "forward"
    target_group_arn = aws_lb_target_group.lb_targetgroup.arn
  }
}

#################################################
# Attach Target Group to Corelight Monitor ENI
#################################################
resource "aws_lb_target_group_attachment" "lb_attach" {
  target_group_arn = aws_lb_target_group.lb_targetgroup.arn
  target_id = aws_instance.cl_sensor1.id
}

#################################################
# Create Mirror Target
#################################################
resource "aws_ec2_traffic_mirror_target" "mirrortaget" {
  network_load_balancer_arn = aws_lb.mirrorlb.arn
}

#################################################
# Create Mirror Filter
#################################################
resource "aws_ec2_traffic_mirror_filter" "filter" {
  description = "Mirror Traffic Filter"
}

#################################################
# Create Mirror Filter Rules
#################################################
resource "aws_ec2_traffic_mirror_filter_rule" "ruleout" {
  description = "alltraffic"
  traffic_mirror_filter_id = aws_ec2_traffic_mirror_filter.filter.id
  destination_cidr_block = "0.0.0.0/0"
  source_cidr_block = "0.0.0.0/0"
  rule_number = 1
  rule_action = "accept"
  traffic_direction = "egress"
}

resource "aws_ec2_traffic_mirror_filter_rule" "rulein" {
  description = "alltraffic"
  traffic_mirror_filter_id = aws_ec2_traffic_mirror_filter.filter.id
  destination_cidr_block = "0.0.0.0/0"
  source_cidr_block = "0.0.0.0/0"
  rule_number = 1
  rule_action = "accept"
  traffic_direction = "ingress"
  protocol = 6
  destination_port_range {
    from_port = 0 
    to_port = 65535
  }
  source_port_range {
    from_port = 0
    to_port = 65535 
  }
}


