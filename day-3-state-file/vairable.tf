
variable "vpc_cidr" {
  default = "10.0.0.0/16"
}

variable "public_subnet_cidr" {
  default = "10.0.1.0/24"
}

variable "private_subnet_cidr" {
  default = "10.0.2.0/24"
}

variable "public_az" {
  default = "us-east-1a"
}

variable "private_az" {
  default = "us-east-1b"
}

variable "instance_type" {
  default = "t3.micro"
}
