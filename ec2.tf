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

resource "aws_instance" "vm1" {
  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = var.aws_instance_type
  subnet_id              = aws_subnet.private_a.id
  vpc_security_group_ids = [aws_security_group.ec2.id]

  user_data = <<-EOF
              #!/bin/bash
              dnf update -y
              dnf install -y httpd
              systemctl start httpd
              systemctl enable httpd
              echo "<h1>Hello from vm1</h1>" > /var/www/html/index.html
              EOF

  tags = {
    Name = "project1-vm1"
  }
}

resource "aws_instance" "vm2" {
  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = var.aws_instance_type
  subnet_id              = aws_subnet.private_b.id
  vpc_security_group_ids = [aws_security_group.ec2.id]

  user_data = <<-EOF
              #!/bin/bash
              dnf update -y
              dnf install -y httpd
              systemctl start httpd
              systemctl enable httpd
              echo "<h1>Hello from vm2</h1>" > /var/www/html/index.html
              EOF

  tags = {
    Name = "project1-vm2"
  }
}