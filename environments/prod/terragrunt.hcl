remote_state {
  backend = "s3"
  generate = {
    path      = "_backend.tf"
    if_exists = "overwrite"
  }
  config = {
    bucket = "cryptra-prod-terraform-state"
    key    = "environments/prod/terraform.tfstate"
    region = "ap-northeast-1"
    encrypt = true
    s3_bucket_tags = {
      "Terraform"   = "true"
      "Environment" = "prod"
      "System"      = "Cryptra"
    }
  }
}

dependencies {
  paths = ["./ecr", "./kinesis"]
}

include {
  path = "${get_terragrunt_dir()}/common.hcl"
}