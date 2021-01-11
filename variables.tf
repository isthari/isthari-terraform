variable "bucket" {}
variable "metastorePassword" {
  type    = string
  default = "changeme"
}

variable "cloudRegionId" {}
variable "shortId" {}

variable "region" { 
  type    = string
  default = "us-east-1" 
}

# key security
variable "keyPair" {
  type    = string
  default = null
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
variable "vpc_private_2_net" {
  type    = string
  default = "10.240.3.0/24"
}

##
## AUTOMATIC VARIABLES DO NOT MODIFY
## 
variable "api-server" {
  type = string
  default = "https://saas.isthari.com"
}

variable "metastore-image" {
  type = map
  default = {
    us-east-1 = "ami-0b5e8a42fa961a4d2"
  }
}
