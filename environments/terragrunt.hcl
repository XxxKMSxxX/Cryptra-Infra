locals {
  conf = merge(
    try(yamldecode(file(find_in_parent_folders("global.yaml"))), {}),
    try(yamldecode(file(find_in_parent_folders("environment.yaml"))), {}),
    try(yamldecode(file(find_in_parent_folders("region.yaml"))), {}),
    try(yamldecode(file(find_in_parent_folders("collects.yaml"))), {}),
  )
  tags = {
    Project     = local.conf.project_name
    Environment = local.conf.environment
    Terraform   = "true"
  }
}

remote_state {
  backend = "s3"
  generate = {
    path      = "_backend.tf"
    if_exists = "overwrite"
  }
  config = {
    bucket = "${local.conf.project_name}-${local.conf.environment}-terraform-state"
    key    = "${path_relative_to_include()}/terraform.tfstate"
    region = local.conf.region
    encrypt = true
    s3_bucket_tags = local.tags
  }
}

generate "provider" {
  path      = "_provider.tf"
  if_exists = "overwrite"
  contents  = <<EOF
provider "aws" {
  region = "${local.conf.region}"
}
EOF
}

generate "version" {
  path      = "_version.tf"
  if_exists = "overwrite"
  contents  = <<EOF
terraform {
  required_version = ">= 1.9.1"
}
EOF
}
