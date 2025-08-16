provider "aws" {
  region = "us-east-1"
}

resource "aws_vpc" "FirstVPC" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "FirstVPC"
  }
}

resource "aws_subnet" "FirstSubnet" {
  vpc_id = aws_vpc.FirstVPC.id
  cidr_block = "10.0.1.0/24"
  availability_zone = "us-east-1a"
  map_public_ip_on_launch = true
  tags = {
    Name = "rajeshmodiifed"
  }
}

resource "aws_subnet" "SecondSubnet" {
  vpc_id = aws_vpc.FirstVPC.id
  cidr_block = "10.0.2.0/24"
  availability_zone = "us-east-1b"
  map_public_ip_on_launch = true
  tags = {
    Name = "SecondSubnet"
  }
}
resource "aws_internet_gateway" "FirstInternetGateway" {
  vpc_id = aws_vpc.FirstVPC.id
  tags = {
    Name = "FirstInternetGateway"
  }
}   

resource "aws_route_table" "FirstRouteTable" {
  vpc_id = aws_vpc.FirstVPC.id

  tags = {
    Name = "FirstRouteTable"
  }
}

resource "aws_route" "FirstRoute" {
  route_table_id = aws_route_table.FirstRouteTable.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id = aws_internet_gateway.FirstInternetGateway.id
}

resource "aws_route_table_association" "FirstRouteTableAssociation" {
  subnet_id = aws_subnet.FirstSubnet.id
  route_table_id = aws_route_table.FirstRouteTable.id
}

resource "aws_route_table_association" "SecondRouteTableAssociation" {
  subnet_id = aws_subnet.SecondSubnet.id
  route_table_id = aws_route_table.FirstRouteTable.id
}

resource "aws_security_group" "FirstSecurityGroup" {
  name = "FirstSecurityGroup"
  description = "FirstSecurityGroup"
  vpc_id = aws_vpc.FirstVPC.id

  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "FirstSecurityGroup"
  }
}

resource "aws_lb_target_group" "FirstTargetGroup" {
  name = "FirstTargetGroup"
  port = 80
  protocol = "HTTP"
  vpc_id = aws_vpc.FirstVPC.id
  tags = {
    Name = "rajeshmoidified"
  }
  health_check {
    path = "/"
    port = 80
    protocol = "HTTP"
    interval = 30
    timeout = 10
    healthy_threshold = 2
    unhealthy_threshold = 2
    matcher = "200"
  }
}

resource "aws_lb" "FirstLoadBalancer" {
  name = "FirstLoadBalancer"
  internal = false
  load_balancer_type = "application"
  security_groups = [aws_security_group.FirstSecurityGroup.id]
  subnets = [aws_subnet.FirstSubnet.id, aws_subnet.SecondSubnet.id]
  enable_cross_zone_load_balancing = true
  tags = {
    Name = "FirstLoadBalancer"
  }
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_lb_listener" "FirstLoadBalancerListener" {
  load_balancer_arn = aws_lb.FirstLoadBalancer.arn
  port = 80
  protocol = "HTTP"
  default_action {
    type = "forward"
    target_group_arn = aws_lb_target_group.FirstTargetGroup.arn
  }
}

resource "aws_launch_template" "FirstLaunchTemplate" {
  name = "FirstLaunchTemplate"
  image_id = "ami-020cba7c55df1f615"
  instance_type = "t2.micro"
  key_name = "vault"
  vpc_security_group_ids = [aws_security_group.FirstSecurityGroup.id]
  tags = {
    Name = "FirstLaunchTemplate"
  }
  network_interfaces {
    associate_public_ip_address = true
    security_groups = [aws_security_group.FirstSecurityGroup.id]
  }
}

resource "aws_autoscaling_group" "FirstAutoScalingGroup" {
  name = "FirstAutoScalingGroup"
  vpc_zone_identifier = [aws_subnet.FirstSubnet.id, aws_subnet.SecondSubnet.id]
  desired_capacity = 2
  max_size = 3
  min_size = 1
  target_group_arns = [aws_lb_target_group.FirstTargetGroup.arn]
  launch_template {
    id = aws_launch_template.FirstLaunchTemplate.id

  }
  tag {
    key = "Name"
    value = "FirstAutoScalingGroup"
    propagate_at_launch = true
  }
}

output "aws_vpc_ids" {
    description = "the id of vpc"
    value = aws_vpc.FirstVPC.id
}

output "subnet_ids" {
    description = "the value of subnet id "
    value =[aws_subnet.FirstSubnet.id, aws_subnet.SecondSubnet.id]
}
