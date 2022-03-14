# varaibles can change at runtime


variable "region" {
    description = "Amazon region"
    type = string
    default = "ap-southeast-2"
}

variable "bucket_name" {
    description = "s3 bucket name"
    type = string
    default = "fit5225-ass2-images-prod"
}
variable "function_name" {
  description = "object detection"
  type = string
  default = "object_detection"
}

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


variable "db_name" {
  description = "name for database"
  type = string
  default = "server_db"
}

variable "db_user" {
  description = "username for database"
  type = string
  # sensitive = true
  default = "admin"
}


variable "db_pass" {
  description = "password for database"
  type = string
  # sensitive = true
  default = "00abf0511a7f4cee5"
}
