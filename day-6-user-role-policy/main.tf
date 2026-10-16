# Get AWS-managed S3 Full Access policy
data "aws_iam_policy" "s3_full_access" {
  arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
}

# Create IAM User
resource "aws_iam_user" "user" {
  name = var.iam_user_name
}

# Attach S3 Full Access to IAM User
resource "aws_iam_user_policy_attachment" "user_policy" {
  user       = aws_iam_user.user.name
  policy_arn = data.aws_iam_policy.s3_full_access.arn
}

# Create IAM Role for EC2
resource "aws_iam_role" "role" {
  name = var.iam_role_name

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })
}

# Attach S3 Full Access to IAM Role
resource "aws_iam_role_policy_attachment" "role_policy" {
  role       = aws_iam_role.role.name
  policy_arn = data.aws_iam_policy.s3_full_access.arn
}