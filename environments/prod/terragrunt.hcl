remote_state {
  backend = "s3"
  generate = {
    path      = "_backend.tf"
    if_exists = "overwrite"
  }
  config = {
    bucket = "cryptra-prod-terraform-state"
    prefix = "prod/terraform.tfstate"
    region = "ap-northeast-1"
    encrypt = true
    s3_bucket_tags = {
      "Terraform"   = "true"
      "Environment" = "prod"
      "System"      = "Cryptra"
    }
  }
}

generate "provider" {
  path      = "provider.tf"
  if_exists = "overwrite"
  contents  = <<EOF
provider "aws" {
  region = "ap-northeast-1"
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

dependencies {
  paths = ["./ecr", "./kinesis"]
}
