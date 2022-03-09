# varaibles can change at runtime


variable "region" {
    description = "Amazon region"
    type = string
    default = "ap-southeast-2"
}

variable "bucket_name" {
    description = "s3 bucket name"
    type = string
}

# variable "domain" {
#   description = "value"

# }

variable "ami" {
    description = "Amazon machine image for ec2 instance"
    type = string
    default = "ami-00abf0511a7f4cee5"
}

variable "instance_type" {
    description = "ec2 instance type"
    type = string
    default = "t2.micro"
}

variable "db_user" {
  description = "username for database"
  type = string
  sensitive = true
}


variable "db_pass" {
  description = "password for database"
  type = string
  sensitive = true
}
