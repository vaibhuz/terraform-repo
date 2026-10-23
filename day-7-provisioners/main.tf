provider "aws" {
    region = "us-east-1"
  
}
# Key Pair
resource "aws_key_pair" "example" {
  key_name   = "task"
  public_key = file("~/.ssh/id_ed25519.pub")
}

# VPC
resource "aws_vpc" "myvpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "MyVPC"
  }
}

# Subnet
resource "aws_subnet" "sub1" {
  vpc_id                  = aws_vpc.myvpc.id
  cidr_block              = "10.0.0.0/24"
  map_public_ip_on_launch = true

  tags = {
    Name = "PublicSubnet"
  }
}

# Internet Gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.myvpc.id
}

# Route Table
resource "aws_route_table" "RT" {
  vpc_id = aws_vpc.myvpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
}

# Associate Route Table
resource "aws_route_table_association" "rta1" {
  subnet_id      = aws_subnet.sub1.id
  route_table_id = aws_route_table.RT.id
}

# Security Group
resource "aws_security_group" "webSg" {
  name   = "web"
  vpc_id = aws_vpc.myvpc.id

  ingress {
    description = "Allow HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Allow SSH"
    from_port   = 22
    to_port     = 22
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

# EC2 Instance (Ubuntu)
resource "aws_instance" "server" {
  ami                         = "ami-0d97d7f07b25dd693" # Ubuntu AMI us-east-1
  instance_type               = "t2.micro"
  key_name                    = aws_key_pair.example.key_name
  subnet_id                   = aws_subnet.sub1.id
  vpc_security_group_ids      = [aws_security_group.webSg.id]
  associate_public_ip_address = true
#   user_data = <<-EOF
#               #!/bin/bash
#               sudo apt update -
#               sudo apt install -y mysql-client
#               EOF

  tags = {
    Name = "UbuntuServer"
  }

#   connection {
#     type        = "ssh"
#     user        = "ubuntu"                          # ✅ Correct for Ubuntu AMIs
#     private_key = file("~/.ssh/id_ed25519")          # Path to private key
#     host        = self.public_ip  #or we can use aws_instance.server.public_ip
#     timeout     = "5m"
#   }

#   provisioner "file" {
#     source      = "file10"
#     destination = "/home/ubuntu/file10" #destination path on the remote instance copy the file10 from local to remote instance with the name file10
#   }

#   provisioner "remote-exec" {
#     inline = [
#       "touch /home/ubuntu/file200",
#       "echo 'hello from multicloud devops nareshit' >> /home/ubuntu/file200"
#     ]
#   }
#    provisioner "local-exec" {
#     command = "touch file500" 
    
   
#  }
 }
resource "null_resource" "run_script" {

    connection {
      host        = aws_instance.server.public_ip
      user        = "ubuntu"
      private_key = file("~/.ssh/id_ed25519")
    }
     provisioner "file" {
    source      = "dev.sh"
    destination = "/home/ubuntu/dev.sh" #destination path on the remote instance copy the file10 from local to remote instance with the name file10
  }

  provisioner "remote-exec" {
    inline = [
       #"echo 'hello from veera FDE NIT' >> /home/ubuntu/file200",
      
        "bash /home/ubuntu/dev.sh" # Assuming dev.sh is already on the instance 
    ]
  }

#   triggers = {
#     always_run = "${timestamp()}" # This will ensure the provisioner runs every time you apply, as the timestamp will always change.
#   }
 triggers = {
 script_hash = filemd5("dev.sh") # Rerun only if script changes
}
}


#Solution-2 to Re-Run the Provisioner
#Use terraform taint to manually mark the resource for recreation:
# terraform taint aws_instance.server
# terraform apply