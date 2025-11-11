module "vpc" {
  source = "../../modules/vpc"
  name   = "secure-${var.env}"
  cidr   = "10.11.0.0/16"
}

module "kms" {
  source = "../../modules/kms"
  alias  = "secure-${var.env}"
}

module "logging" {
  source  = "../../modules/logging"
  org_env = var.env
}

resource "random_id" "suffix" { byte_length = 3 }

module "secure_bucket" {
  source      = "../../modules/s3-secure-bucket"
  bucket_name = "secure-${var.env}-artifacts-${random_id.suffix.hex}"
  kms_key_id  = module.kms.key_id
}

module "iam_baseline" {
  source = "../../modules/iam-baseline"
  env    = var.env
}
