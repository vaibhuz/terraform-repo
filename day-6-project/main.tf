# -------------------------
# VPC
# -------------------------

resource "aws_vpc" "alfa" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = var.vpc_name
  }
}

# -------------------------
# Public Subnets: 1a and 1b
# -------------------------

resource "aws_subnet" "public" {
  count = 2

  vpc_id                  = aws_vpc.alfa.id
  cidr_block              = var.public_subnet_cidrs[count.index]
  availability_zone       = var.availability_zones[count.index]
  map_public_ip_on_launch = true

  tags = {
    Name = "alfa-public-${count.index + 1}"
    Tier = "public"
  }
}

# -------------------------
# Private Application Subnets
# -------------------------

resource "aws_subnet" "private" {
  count = 2

  vpc_id                  = aws_vpc.alfa.id
  cidr_block              = var.private_subnet_cidrs[count.index]
  availability_zone       = var.availability_zones[count.index]
  map_public_ip_on_launch = false

  tags = {
    Name = "alfa-private-${count.index + 1}"
    Tier = "application"
  }
}

# -------------------------
# Private Database Subnets
# -------------------------

resource "aws_subnet" "database" {
  count = 2

  vpc_id                  = aws_vpc.alfa.id
  cidr_block              = var.database_subnet_cidrs[count.index]
  availability_zone       = var.availability_zones[count.index]
  map_public_ip_on_launch = false

  tags = {
    Name = "alfa-database-${count.index + 1}"
    Tier = "database"
  }
}

# -------------------------
# Internet Gateway
# -------------------------

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.alfa.id

  tags = {
    Name = "alfa-igw"
  }
}

# -------------------------
# Elastic IP for NAT
# -------------------------

resource "aws_eip" "nat" {
  domain = "vpc"

  tags = {
    Name = "alfa-nat-eip"
  }
}

# -------------------------
# NAT Gateway in Public AZ 1a
# -------------------------

resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public[0].id

  depends_on = [aws_internet_gateway.igw]

  tags = {
    Name = "alfa-nat"
  }
}

# -------------------------
# Public Route Table
# -------------------------

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.alfa.id

  tags = {
    Name = "alfa-public-rt"
  }
}

resource "aws_route" "public_internet" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.igw.id
}

resource "aws_route_table_association" "public" {
  count = 2

  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

# -------------------------
# Private Route Table
# -------------------------

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.alfa.id

  tags = {
    Name = "alfa-private-rt"
  }
}

resource "aws_route" "private_nat" {
  route_table_id         = aws_route_table.private.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.nat.id
}

# Associate both application subnets
resource "aws_route_table_association" "private" {
  count = 2

  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private.id
}

# Associate both database subnets with the private route table.
# This gives them outbound routing through NAT, but does not
# make them publicly reachable.
resource "aws_route_table_association" "database" {
  count = 2

  subnet_id      = aws_subnet.database[count.index].id
  route_table_id = aws_route_table.private.id
}

# -------------------------
# Security Group: ALB
# -------------------------

resource "aws_security_group" "alb_sg" {
  name        = "alfa-alb-sg"
  description = "Allow public HTTP traffic to the ALB"
  vpc_id      = aws_vpc.alfa.id

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

  tags = {
    Name = "alfa-alb-sg"
  }
}

# -------------------------
# Security Group: EC2
# -------------------------

resource "aws_security_group" "ec2_sg" {
  name        = "alfa-ec2-sg"
  description = "Allow web traffic from ALB"
  vpc_id      = aws_vpc.alfa.id

  ingress {
    description     = "HTTP from ALB only"
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "alfa-ec2-sg"
  }
}

# -------------------------
# Security Group: RDS
# -------------------------

resource "aws_security_group" "db_sg" {
  name        = "alfa-db-sg"
  description = "Allow MySQL from application EC2 instances"
  vpc_id      = aws_vpc.alfa.id

  ingress {
    description     = "MySQL from application tier"
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.ec2_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "alfa-db-sg"
  }
}

# -------------------------
# Application Load Balancer
# -------------------------

resource "aws_lb" "alfa" {
  name               = var.alb_name
  internal           = false
  load_balancer_type = "application"

  subnets         = aws_subnet.public[*].id
  security_groups = [aws_security_group.alb_sg.id]

  tags = {
    Name = var.alb_name
  }
}

# -------------------------
# Target Group
# -------------------------

resource "aws_lb_target_group" "alfa" {
  name     = var.target_group_name
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.alfa.id

  health_check {
    enabled             = true
    path                = "/"
    protocol            = "HTTP"
    matcher             = "200"
    healthy_threshold   = 2
    unhealthy_threshold = 3
    interval            = 30
  }

  tags = {
    Name = var.target_group_name
  }
}

# -------------------------
# ALB Listener
# -------------------------

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.alfa.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.alfa.arn
  }
}

# -------------------------
# Launch Template / AMI
# -------------------------

resource "aws_launch_template" "alfa" {
  name_prefix   = "alfa-web-"
  image_id      = var.ami_id
  instance_type = var.instance_type

  vpc_security_group_ids = [aws_security_group.ec2_sg.id]

  user_data = base64encode(<<-EOF
    #!/bin/bash
    dnf install -y httpd
    systemctl enable --now httpd
    echo "Hello from alfa-vpc web server" > /var/www/html/index.html
  EOF
  )

  tag_specifications {
    resource_type = "instance"

    tags = {
      Name = "alfa-web-server"
    }
  }

  lifecycle {
    create_before_destroy = true
  }
}

# -------------------------
# Auto Scaling Group
# -------------------------

resource "aws_autoscaling_group" "alfa" {
  name                = var.asg_name
  min_size            = var.min_size
  max_size            = var.max_size
  desired_capacity    = var.desired_capacity
  vpc_zone_identifier = aws_subnet.private[*].id

  target_group_arns = [aws_lb_target_group.alfa.arn]

  launch_template {
    id      = aws_launch_template.alfa.id
    version = "$Latest"
  }

  health_check_type         = "ELB"
  health_check_grace_period = 180

  tag {
    key                 = "Name"
    value               = "alfa-asg-instance"
    propagate_at_launch = true
  }

  depends_on = [aws_lb_listener.http]
}

# -------------------------
# RDS DB Subnet Group
# -------------------------

resource "aws_db_subnet_group" "alfa" {
  name        = "alfa-db-subnet-group"
  description = "Private database subnets across two AZs"
  subnet_ids  = aws_subnet.database[*].id

  tags = {
    Name = "alfa-db-subnet-group"
  }
}

# -------------------------
# Private RDS Database
# -------------------------

resource "aws_db_instance" "alfa" {
  identifier = var.db_identifier

  engine         = "mysql"
  instance_class = var.db_instance_class

  allocated_storage = var.db_allocated_storage
  storage_type      = "gp3"
  storage_encrypted = true

  db_name  = var.db_name
  username = var.db_username
  password = var.db_password

  db_subnet_group_name   = aws_db_subnet_group.alfa.name
  vpc_security_group_ids = [aws_security_group.db_sg.id]

  availability_zone   = var.availability_zones[0]
  publicly_accessible = false
  multi_az            = false

  backup_retention_period = 1
  auto_minor_version_upgrade = true

  skip_final_snapshot = true
  deletion_protection = false

  tags = {
    Name = var.db_identifier
  }
}

# -------------------------
# Outputs
# -------------------------

output "vpc_id" {
  value = aws_vpc.alfa.id
}

output "alb_dns_name" {
  value = aws_lb.alfa.dns_name
}

output "target_group_arn" {
  value = aws_lb_target_group.alfa.arn
}

output "database_endpoint" {
  value = aws_db_instance.alfa.address
}

output "autoscaling_group_name" {
  value = aws_autoscaling_group.alfa.name
}