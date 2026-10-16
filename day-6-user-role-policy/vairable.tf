variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "iam_user_name" {
  description = "IAM user name"
  type        = string
}

variable "iam_role_name" {
  description = "IAM role name"
  type        = string
}