data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }
}

resource "aws_security_group" "ec2" {
  name        = "project1-ec2-sg"
  description = "Allow HTTP into the EC2 instances from the ALB"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "project1-ec2-sg"
  }
}

# ec2 launch template for the auto scaling group
resource "aws_launch_template" "vm" {
  name_prefix   = "instances"
  image_id      = "data.aws_ami.amazon_linux.id"
  instance_type = "t3.micro"
  vpc_security_group_ids = [aws_security_group.ec2.id]
  
  user_data = base64encode(<<-EOF
            #!/bin/bash
            dnf update -y
            dnf install -y httpd
            systemctl start httpd
            systemctl enable httpd

            cat <<'HTML' > /var/www/html/index.html
            <!DOCTYPE html>
            <html>
            <head>
              <title>Hello</title>
              <style>
                body {
                  font-family: -apple-system, 'Segoe UI', Arial, sans-serif;
                  background: #000000;
                  color: #ffffff;
                  display: flex;
                  flex-direction: column;
                  align-items: center;
                  justify-content: center;
                  height: 100vh;
                  margin: 0;
                }
                h1 {
                  font-size: 48px;
                  font-weight: 600;
                  margin: 0;
                }
                p {
                  color: #888888;
                  font-size: 16px;
                  margin-top: 12px;
                }
              </style>
            </head>
            <body>
              <h1>Hello from the cloud</h1>
              <p>Three-tier AWS app &middot; built with Terraform</p>
            </body>
            </html>
            HTML
            EOF
)

}
# Auto scaling group
resource "aws_autoscaling_group" "vm"{
  desired_capacity   = 2
  max_size           = 2
  min_size           = 2
  vpc_zone_identifier  = [aws_subnet.private_a.id,aws_subnet.private_b.id]

  launch_template {
    id      = aws_launch_template.vm.id
    version = "$Latest"
  }
  # every EC2 instance launched by the ASG gets that Name tag
   tag {
  key                 = "Name"
  value               = "auto-scaling-group"
  propagate_at_launch = true  
   }
}
