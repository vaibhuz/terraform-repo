
resource "aws_security_group" "cloud-project-vaibhav" {
  name        = "cloud-project-vaibhav"
  description = "Allow inbound traffic from different CIDRs"

  ingress = [
    for rule in [
      { port = 22,   cidr = "0.0.0.0/32", description = "SSH access" },
      { port = 80,   cidr = "0.0.0.0/0",         description = "HTTP access" },
      { port = 443,  cidr = "0.0.0.0/0",         description = "HTTPS access" },
      { port = 8080, cidr = "10.0.1.0/24",        description = "App from public subnet" },
      { port = 9000, cidr = "10.0.2.0/24",        description = "Service from private subnet" },
      { port = 3000, cidr = "192.168.1.0/24",      description = "Grafana or app access" },
      { port = 8082, cidr = "10.0.1.0/24",        description = "Service port 8082" },
      { port = 8081, cidr = "10.0.2.0/24",        description = "Service port 8081" },
      { port = 3306, cidr = "10.0.2.0/24",        description = "MySQL from private subnet" },
      { port = 5000, cidr = "10.0.1.0/24",        description = "Application port 5000" }
    ] : {
      description      = rule.description
      from_port        = rule.port
      to_port          = rule.port
      protocol         = "tcp"
      cidr_blocks      = [rule.cidr]
      ipv6_cidr_blocks = []
      prefix_list_ids  = []
      security_groups  = []
      self             = false
    }
  ]

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "cloud-project-vaibhav"
  }
}
