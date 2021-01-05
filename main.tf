provider "aws" {
  region = var.region
  version = "~> 2.70.0"
}

provider "local" {
  version = "~> 1.4"
}
