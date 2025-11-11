resource "aws_kms_key" "main" {
  description             = "KMS key for ${var.alias}"
  deletion_window_in_days = 10
  enable_key_rotation     = true

  tags = {
    Name = var.alias
  }
}

resource "aws_kms_alias" "main" {
  name          = "alias/${var.alias}"
  target_key_id = aws_kms_key.main.key_id
}
