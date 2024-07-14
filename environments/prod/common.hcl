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