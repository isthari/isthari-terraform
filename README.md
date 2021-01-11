# Introduction
This document describe the procedure to deploy a new Cloud Region environment for your Isthari SaaS account

The whole process is based on IaaS (terraform) and is completely automated

# Prerequisites

Any linux environment (it must include curl utility)

Terraform [Download](https://www.terraform.io/downloads.html)

Your AWS credentials with administrator rights

# Installation

Create a Cloud Region in the web interface and write down the following values:

```
cloudRegionId = "PROVIDED-CLOUD-REGION-ID"
shortId = "PROVIDED-SHORT-ID"
```

Clone this repository

```
git clone https://github.com/isthari/isthari-terraform
```

Edit the file terraform.tfvars and modify the following values:

* cloudRegionId, provided from the web 
* shortId, provided from the web
* bucket, the S3 bucket to store your data lake. It must exists !!!
* metastorePassword, password of the database used by the metastore / metadata service
* region, AWS region to deploy your environment

Recommended:

* keyPair, name of the AWS key pair to access your instances

# Production environment

Terraform store the full configuration in your local disk. For production environment is HIGHLY recommended to store this information in the cloud.

Edit the file main.tf, uncomment the last block and configure the name of the S3 bucket to store your configuration

```
# Configure for production environments
# terraform {
#   backend "s3" {
#     bucket = "CONFIGURE-BUCKET-NAME"
#     key = "isthari/private/terraform.tfstate"
#   }
# }
```

# Optional configuration parameters:

* vpc_net, CIDR of the VPC to be deployed
* vpc_public_1_net, vpc_public_2_net, CIDR for the public net. It should belong to the VPC range
* vpc_private_1_net, vpc_private_2_net, CIDR for the public net. It should belong to the VPC range