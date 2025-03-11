variable "aws_region" {
  type        = string
  default     = "eu-north-1"
}

variable "instance_type" {
  type        = string
  default     = "t3.micro"
}

variable "my_public_key" {
  type        = string
}

variable "lecturer_public_key" {
  type        = string
}