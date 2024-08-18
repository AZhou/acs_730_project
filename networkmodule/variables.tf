# Provision public subnets in custom VPC
variable "public_cidr_blocks" {

  type        = list(string)
  description = "Public Subnet CIDRs"
}

variable "private_cidr_blocks" {
  type        = list(string)
  description = "Private Subnet CIDRs"
}

# VPC CIDR range
variable "vpc_cidr" {
  type        = string
  description = "VPC to host static web site"
}

# Default tags
variable "default_tags" {
  default     = {}
  type        = map(any)
  description = "Default tags to be appliad to all AWS resources"
}

# Prefix to identify resources
variable "prefix" {
  #default     = "week7"
  type        = string
  description = "Name prefix"
}


# Variable to signal the current environment 
variable "env" {
  default     = "prod"
  type        = string
  description = "Deployment Environment"
}
