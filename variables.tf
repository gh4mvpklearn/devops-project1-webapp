#test1
variable "aws-region" {
    description = "default AWS region:"
    type = string
    default = "us-east-1"
}

variable "vpc-cidr-block" {
    description = "VPC default CIDR block"
    type = string
    default = "10.0.0.0/16"
}

variable "instance_type" {
    description = "Type of the default instance:"
    type = string
    default = "t2.micro"
}

/*variable "access_key" {
    description = "access key"
    type = string
    sensitive = true
  
}

variable "secret_key" {
    description = "secret key"
    type = string
    sensitive = true
  
}*/