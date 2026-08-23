variable "aws_instance_type" {
    description = "The instance type for the EC2 instances."
    type = string
    default = "t3.micro"
}

variable "aws_region" {
    description = "The AWS region to deploy resources in."
    type = string
    default = "us-east-1"
}
// Variable for the VPC CIDR block
variable "vpc_cidr" {
    description = "The CIDR block for the VPC."
    type = string
    default = "10.0.0.0/16"
}

// Variable for the public subnet CIDR blocks
variable "public_a_subnet_cidr" {
    description = "The CIDR block for the public subnet A."
    type = string
    default = "10.0.1.0/24"
}

variable "public_b_subnet_cidr" {
    description = "The CIDR block for the public subnet B."
    type = string
    default = "10.0.2.0/24"
}
variable "private_a_subnet_cidr" {
    description = "The CIDR block for the private subnet A."
    type = string
    default = "10.0.3.0/24"
}
variable "private_b_subnet_cidr" {
    description = "The CIDR block for the private subnet B."
    type = string
    default = "10.0.4.0/24"

}

// Variable for the RDS instance class
variable "rds_instance_class" {
    description = "The instance class for the RDS database."
    type = string
    default = "db.t3.micro"
}

variable "rds_username" {
    description = "The username for the RDS database."
    type = string
    default = "admin"
    sensitive = false
}
variable "rds_password" {
    description = "The password for the RDS database."
    type = string
    sensitive = true
}
