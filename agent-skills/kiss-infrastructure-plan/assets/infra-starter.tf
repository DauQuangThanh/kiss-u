# Starter Terraform / OpenTofu module.
# Adapt for your cloud + project. See docs/operations/infra.md.

terraform {
  required_version = ">= 1.5.0"
  required_providers {
    # TODO(kiss-infra): pin provider versions
  }

  # TODO(kiss-infra): remote backend with locking
  # backend "s3" { ... }
}

variable "env" {
  type    = string
  default = "dev"
}

variable "cidr" {
  type    = string
  default = "10.0.0.0/16"
}

# Example VPC (AWS). Remove if using another cloud.
# resource "aws_vpc" "main" {
#   cidr_block = var.cidr
#   tags = {
#     Name = "kiss-${var.env}"
#     Env  = var.env
#   }
# }
