resource "aws_instance" "name" {
    ami = "ami-002192a70217ac181"
    instance_type = "t2.micro"
    tags = {
        Name = "dev-2"
    }
  #us-east-1
}

resource "aws_s3_bucket" "name" {
 bucket = "dev-test-prod-vaibhav-nit"
 provider = aws.dev
 #us-west-2
}