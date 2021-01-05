variable "cloudRegionId" {}
variable "shortId" {}

variable "region" { 
  type    = string
  default = "us-east-1" 
}

###
### Network configuration
### 
variable "vpc_net" {
  type    = string
  default = "10.240.0.0/16"
}

# public net
variable "vpc_public_1_net" {
  type    = string
  default = "10.240.0.0/24"
}
variable "vpc_public_2_net" {
  type    = string
  default = "10.240.1.0/24" 
}

# private net
variable "vpc_private_1_net" {
  type    = string
  default = "10.240.2.0/24"
}
