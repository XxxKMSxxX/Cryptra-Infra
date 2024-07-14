locals {
  common_vars  = yamldecode(file("env.yaml"))
  environment  = local.common_vars.environment
  project_name = local.common_vars.project_name
  aws_region   = local.common_vars.aws_region
}

remote_state {
  backend = "s3"
  generate = {
    path      = "backend.tf"
    if_exists = "overwrite"
  }
  config = {
    bucket = "${local.project_name}-${local.environment}-terraform-state"
    key    = "${path_relative_to_include()}/terraform.tfstate"
    region = local.aws_region
    encrypt = true
    s3_bucket_tags = {
      "Terraform"   = "true"
      "Environment" = local.environment
      "Project"     = local.project_name
    }
  }
}

generate "provider" {
  path      = "provider.tf"
  if_exists = "overwrite"
  contents  = <<EOF
provider "aws" {
  region = "${local.aws_region}"
}
EOF
}

generate "version" {
  path      = "version.tf"
  if_exists = "overwrite"
  contents  = <<EOF
terraform {
  required_version = ">= 1.9.1"
}
EOF
}
