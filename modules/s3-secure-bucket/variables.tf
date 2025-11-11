variable "bucket_name" {
  type        = string
  description = "Name of the S3 bucket"
}

variable "kms_key_id" {
  type        = string
  description = "KMS key ID for bucket encryption"
}
