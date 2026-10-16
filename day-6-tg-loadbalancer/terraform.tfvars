aws_region = "us-west-2"

vpc_name = "alfa-vpc"
vpc_cidr = "10.0.0.0/16"

availability_zones = [
  "us-west-2a",
  "us-west-2b"
]

public_subnet_cidrs = [
  "10.0.1.0/24",
  "10.0.2.0/24"
]

private_subnet_cidrs = [
  "10.0.11.0/24",
  "10.0.12.0/24"
]

database_subnet_cidrs = [
  "10.0.21.0/24",
  "10.0.22.0/24"
]

# EC2 AMI
# Replace with a valid AMI ID in us-west-2.
# Use your own customized AMI if you already created one.
ami_id        = "ami-0ed59cbb87dfa8dba"
instance_type = "t3.micro"

# Load Balancer
alb_name          = "alfa-app-alb"
target_group_name = "alfa-app-tg"

# Auto Scaling
asg_name         = "alfa-web-asg"
desired_capacity = 2
min_size         = 2
max_size         = 3

# RDS Database
db_identifier       = "database-1"
db_name             = "database1"
db_username         = "admin"
db_password         = "vaibhav123"
db_instance_class   = "db.t3.micro"
db_allocated_storage = 20