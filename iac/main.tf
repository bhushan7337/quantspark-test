terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "4.49.0"
    }
  }
}

provider "aws" {
  region     = "us-east-1"
  access_key = "${var.aws_key}"
  secret_key = "${var.aws_key_secret}"
  //token = "IQoJb3JpZ2luX2VjEH0aCXVzLWVhc3QtMSJGMEQCIFPL6CLW7F9ewS14jJDNEi7yoS34oCQ9Pkno/MlrmFZ3AiB9Lu3CN6qjUlCDa1VcOqp088vmCU+VD5Eo4WyT9PnyGSqnAwim//////////8BEAMaDDU0MzU2NjA4ODk4NSIMi6DwW4+pLSmD3ioQKvsCaj1hwq7DWRvHI7Lckq4wAVsNU7g8C9Z8waHk05vvWYVLrDZ31ILlAfTAFEhjPIzWo9WnunUTCMYc2T2x7GPO4KM5pOqG7eTPyPJB+xCUv29PJn2+SllYLnz7kIA4P6og2lur9lL2Lio+wBTHFe3uKHHk/K+fJtEpCzDrQB4x4uBZs+VEaobasYbwcZwtfKDgfxyMGB2800G3EH473Hvgznk6Swq9k7ntfmkJ9ogWkHXCjDh/IiT9zntogJvyEzdoe105n/XRCpd3OlrPTW++6IJQRZ318MJazHd9aScsJsyNmeeAeVxmDc8j9ReSlD6j1bqhYTxTtFfo+bJelkuA6PwwAjrQ7XucPSEI4qXfZWA1pzBV9glAn7KQUZXDSoR5r/OYccs7EG0bhybT/CkvmgI8WG/JZAUOQFk6J4nj0H8Wf0YUUIVwbZH01CWw+JDoL8hQi48QktH0IVIKuZHSTsdZUKAGzpMw+gymz3qwmSTUSbVUUPPyRUo54TDp+vOpBjqnAY+4liFm5uThyhWzLAIv4BmJL/yrh2H+FG8CebZOtk2s6jdshud3SsLygSTKWf4y0gcAUPgSHrpQAilHQ96OlBubyYbh7GctMnhUJeqjxxyr0GR2cwrUtSX/fLZZ29dXbvbYzEgE7PVOy2IfJHPadO3sEL3AzcS3vv6FEWdSksruwLEl0t38euFM8YF+z1fcbRp3Vt/cuXZZx2QufttntTTPrSlHJd5L"
}

resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
  
  tags = {
    Name = "${var.vpc_name}"
  }
}

resource "aws_subnet" "public_a" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "10.0.1.0/24"
  availability_zone = "us-east-1a"

  tags = {
    Name = "public_a"
  }
}

resource "aws_subnet" "public_b" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "10.0.2.0/24"
  availability_zone = "us-east-1b"

  tags = {
    Name = "public_b"
  }
}

resource "aws_subnet" "public_c" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "10.0.3.0/24"
  availability_zone = "us-east-1c"

  tags = {
    Name = "public_c"
  }
}

resource "aws_internet_gateway" "main-igw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "main-igw"
  }
}

resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main-igw.id
  }

  tags = {
    Name = "public_rt"
  }
}

resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.public_a.id
  route_table_id = aws_route_table.public_rt.id
}

resource "aws_route_table_association" "b" {
  subnet_id      = aws_subnet.public_b.id
  route_table_id = aws_route_table.public_rt.id
}

resource "aws_route_table_association" "c" {
  subnet_id      = aws_subnet.public_c.id
  route_table_id = aws_route_table.public_rt.id
}

resource "aws_security_group" "my_sg" {
  name        = "my-sg"
  vpc_id      = aws_vpc.main.id

  ingress {
    description      = "Allow http from everywhere"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  ingress {
    description      = "Allow http from everywhere"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  egress {
    description      = "Allow outgoing traffic"
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  tags = {
    Name = "my-sg"
  }
}

resource "aws_lb" "my_alb" {
  name               = "my-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.my_sg.id]
  subnets            = [aws_subnet.public_a.id, aws_subnet.public_b.id, aws_subnet.public_c.id]
}

resource "aws_lb_listener" "my_lb_listener" {
  load_balancer_arn = aws_lb.my_alb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.my_tg.arn
  }
}

resource "aws_lb_target_group" "my_tg" {
  name     = "my-tg"
  target_type = "instance"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id
}

resource "aws_launch_template" "my_launch_template" {

  name = "my_launch_template"
  
  image_id = "ami-0fc5d935ebf8bc3bc"
  instance_type = "t2.micro"
  key_name = "ubuntu"
  
  user_data = filebase64("../app/app.sh")

  block_device_mappings {
    device_name = "/dev/sda1"

    ebs {
      volume_size = 8
      volume_type = "gp2"
      encrypted = false
    }
  }

  network_interfaces {
    associate_public_ip_address = true
    security_groups = [aws_security_group.my_sg.id]
  }
}

resource "aws_autoscaling_group" "my_asg" {
  name                      = "my_asg"
  max_size                  = 5
  min_size                  = 3
  health_check_type         = "ELB"
  desired_capacity          = 3
  health_check_grace_period = 300
  target_group_arns = [aws_lb_target_group.my_tg.arn]

  vpc_zone_identifier       = [aws_subnet.public_a.id, aws_subnet.public_b.id, aws_subnet.public_c.id]
  
  launch_template {
    id      = aws_launch_template.my_launch_template.id
    version = "$Latest"
  }
}

resource "aws_autoscaling_policy" "scale_up" {
  name                   = "scale_up"
  policy_type            = "SimpleScaling"
  autoscaling_group_name = aws_autoscaling_group.my_asg.name
  adjustment_type        = "ChangeInCapacity"
  scaling_adjustment     = "1"    # add one instance
  cooldown               = "300"  # cooldown period after scaling
}

resource "aws_cloudwatch_metric_alarm" "scale_up_alarm" {
  alarm_name          = "scale-up-alarm"
  alarm_description   = "asg-scale-up-cpu-alarm"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "1"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "120"
  statistic           = "Average"
  threshold           = "50"
  dimensions = {
    "AutoScalingGroupName" = aws_autoscaling_group.my_asg.name
  }
  actions_enabled = true
  alarm_actions   = [aws_autoscaling_policy.scale_up.arn]
}

resource "aws_autoscaling_policy" "scale_down" {
  name                   = "asg-scale-down"
  autoscaling_group_name = aws_autoscaling_group.my_asg.name
  adjustment_type        = "ChangeInCapacity"
  scaling_adjustment     = "-1"
  cooldown               = "300"
  policy_type            = "SimpleScaling"
}

# resource "aws_cloudwatch_metric_alarm" "scale_down_alarm" {
#   alarm_name          = "asg-scale-down-alarm"
#   alarm_description   = "asg-scale-down-cpu-alarm"
#   comparison_operator = "LessThanOrEqualToThreshold"
#   evaluation_periods  = "1"
#   metric_name         = "CPUUtilization"
#   namespace           = "AWS/EC2"
#   period              = "120"
#   statistic           = "Average"
#   threshold           = "30"
#   dimensions = {
#     "AutoScalingGroupName" = aws_autoscaling_group.my_asg.name
#   }
#   actions_enabled = true
#   alarm_actions   = [aws_autoscaling_policy.scale_down.arn]
# }