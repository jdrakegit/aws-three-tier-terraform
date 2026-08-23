//alb security group
resource "aws_security_group" "alb" {
  name        = "project1-alb-sg"
  description = "Allow HTTP into the ALB (inbound)"
  vpc_id      = aws_vpc.main.id

  //inbound
  ingress {
    description = "HTTP from anywhere"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  //outbound
  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]

  }

  tags = {
    Name = "project1-alb-sg"
  }

}
//alb
resource "aws_lb" "main" {
  name               = "project1-lb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = [aws_subnet.public_a.id, aws_subnet.public_b.id]

  tags = {
    Name = "project1-alb"
  }
}
//alb target group
resource "aws_lb_target_group" "main" {
  name     = "project1-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id

  health_check {
    path                = "/"
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 5
    interval            = 30
  }
  tags = {
    Name = "project1-tg"
  }
}

// attach vm1 to the target group
resource "aws_lb_target_group_attachment" "vm1" {
  target_group_arn = aws_lb_target_group.main.arn
  target_id        = aws_instance.vm1.id
  port             = 80
}

// attach vm2 to the target group
resource "aws_lb_target_group_attachment" "vm2" {
  target_group_arn = aws_lb_target_group.main.arn
  target_id        = aws_instance.vm2.id
  port             = 80
}

// listener 
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.main.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.main.arn
  }
}