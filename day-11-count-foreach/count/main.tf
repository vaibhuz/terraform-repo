variable "nit" {
  type = list(string)
  default = ["dev","test","prod"]
}



resource "aws_instance" "name" {
    ami = "ami-0d27e0fb3bac4d724"
    instance_type = "t2.medium"
    count=length(var.nit)
    tags = {
        Name = var.nit[count.index]
    }

  
}