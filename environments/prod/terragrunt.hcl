terraform {
  source = "../../modules/ecr"

  backend "s3" {
    bucket         = "cryptra-prod-terraform-state"
    key            = "environments/prod/terraform.tfstate"
    region         = "ap-northeast-1"
    encrypt        = true
  }
}

inputs = {
  repository_name = "Cryptra-Collector"
  region          = "ap-northeast-1"
}

generate "provider" {
  path      = "provider.tf"
  if_exists = "overwrite"
  contents  = <<EOF
provider "aws" {
  region = var.region
}
EOF
}

generate "version" {
  path      = "version.tf"
  if_exists = "overwrite"
  contents  = <<EOF
terraform {
  required_version = ">= 0.14"
}
EOF
}

generate "variables" {
  path      = "variables.tf"
  if_exists = "overwrite"
  contents  = <<EOF
variable "repository_name" {
  description = "The name of the ECR repository"
  type        = string
}
variable "region" {
  description = "The AWS region"
  type        = string
}
EOF
}