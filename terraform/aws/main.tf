// create two ec2 with load balancer attached to them. The ec2s must have a apache server html page

resource "aws_vpc" "web" {
  cidr_block = "172.0.0.0/16"
}

resource "aws_subnet" "web-1" {
  vpc_id                  = aws_vpc.web.id
  cidr_block              = "172.0.2.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true
}
resource "aws_subnet" "web-2" {
  vpc_id                  = aws_vpc.web.id
  cidr_block              = "172.0.3.0/24"
  availability_zone       = "us-east-1b"
  map_public_ip_on_launch = true
}


resource "aws_internet_gateway" "web" {
  vpc_id = aws_vpc.web.id
}

resource "aws_route_table" "web" {
  vpc_id = aws_vpc.web.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.web.id
  }
}

resource "aws_route_table_association" "web" {
  subnet_id      = aws_subnet.web-1.id
  route_table_id = aws_route_table.web.id
}
resource "aws_route_table_association" "web" {
  subnet_id      = aws_subnet.web-2.id
  route_table_id = aws_route_table.web.id
}

resource "aws_security_group" "web" {
  name        = "web"
  description = "Allow web inbound traffic"
  vpc_id      = aws_vpc.web.id

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "web_instance_1" {
  ami                         = "ami-0230bd60aa48260c6"
  instance_type               = "t2.micro"
  availability_zone           = "us-east-1a"
  associate_public_ip_address = true
  subnet_id                   = aws_subnet.web-1.id
  vpc_security_group_ids      = [aws_security_group.web.id]

  user_data = <<-EOF
              #!/bin/bash
              yum update -y
              yum install -y httpd
              systemctl start httpd
              systemctl enable httpd
              echo '<h1>Vai Palmeiras Kledinho é</h1>' | tee /var/www/html/index.html
              EOF

  tags = {
    Name = "web"
  }
}

resource "aws_instance" "web_instance_2" {
  ami                         = "ami-0230bd60aa48260c6"
  instance_type               = "t2.micro"
  availability_zone           = "us-east-1a"
  associate_public_ip_address = true
  subnet_id                   = aws_subnet.web-1.id
  vpc_security_group_ids      = [aws_security_group.web.id]

  user_data = <<-EOF
              #!/bin/bash
              yum update -y
              yum install -y httpd
              systemctl start httpd
              systemctl enable httpd
              echo '<h1>Página HTML própria do hike</h1>' | tee /var/www/html/index.html
              EOF

  tags = {
    Name = "web"
  }
}

resource "aws_lb" "lb" {
  name               = "lb-hike"
  load_balancer_type = "application"
  subnets            = [aws_subnet.web-1.id, aws_subnet.web-2.id]
  security_groups    = [aws_security_group.web.id]
}

resource "aws_lb_target_group" "tg" {
  name     = "tg-hike"
  protocol = "HTTP"
  port     = "80"
  vpc_id   = aws_vpc.vpc.id
}

resource "aws_lb_listener" "ec2_lb_listener" {
  protocol          = "HTTP"
  port              = "80"
  load_balancer_arn = aws_lb.lb.arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tg.arn
  }
}
resource "aws_lb_target_group_attachment" "web-1" {
  target_group_arn = aws_lb_target_group.tg.arn
  target_id        = aws_instance.web-1.id
  port             = 80
}

resource "aws_lb_target_group_attachment" "web-2" {
  target_group_arn = aws_lb_target_group.tg.arn
  target_id        = aws_instance.web-2.id
  port             = 80
}