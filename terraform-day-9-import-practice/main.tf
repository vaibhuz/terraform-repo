resource "aws_instance" "name" {
  ami = "ami-08c46876c64a927b8"
  instance_type = "t3.micro"
  tags = {
    Name = "Ec2"
  }
}

resource "aws_s3_bucket" "dev" {
    bucket = "dev-test-prod-nit-bucket"
  
}

resource "aws_s3_bucket_versioning" "versioning_example" {
  bucket = aws_s3_bucket.dev.id
  versioning_configuration {
    status = "Enabled"
  }
}