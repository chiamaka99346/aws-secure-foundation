Feature: Encryption compliance
  All data at rest must be encrypted using AWS KMS

  Scenario: S3 buckets must use KMS encryption
    Given I have aws_s3_bucket_server_side_encryption_configuration defined
    Then it must contain rule
    And it must contain apply_server_side_encryption_by_default
    And it must contain sse_algorithm
    And its value must be aws:kms
