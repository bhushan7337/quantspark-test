variable "vpc_name" {
  type        = string
  description = "vpc name"
  default     = "quant-test-vpc"
}

variable "aws_key" {
  type        = string
  description = "key"
  default     = ""
}

variable "aws_key_secret" {
  type        = string
  description = "key secret"
  default     = ""
}
