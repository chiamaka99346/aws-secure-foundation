terraform {
  backend "s3" {
    bucket         = "chiamaka-tf-state-1762851626.57447"
    key            = "aws-secure-foundation/staging/terraform.tfstate"
    region         = "eu-central-1"
    dynamodb_table = "tf-locks"
    encrypt        = true
  }
}