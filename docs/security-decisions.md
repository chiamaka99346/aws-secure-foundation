# Security Decisions

## Encryption

- **KMS Key Rotation**: Automatic rotation enabled on all KMS keys (annual)
- **S3 Encryption**: All S3 buckets use AWS KMS encryption (aws:kms)
- **Encryption at Rest**: All data stores encrypted with customer-managed keys

## Access Control

- **S3 Public Access**: Blocked at bucket level for all buckets
  - `block_public_acls = true`
  - `block_public_policy = true`
  - `ignore_public_acls = true`
  - `restrict_public_buckets = true`

## Audit & Logging

- **CloudTrail**: Multi-region trail enabled for all AWS API activity
- **Global Service Events**: Captured in CloudTrail logs
- **Log Storage**: Dedicated S3 bucket with versioning enabled
- **Log Retention**: Versioning prevents accidental deletion

## Data Protection

- **S3 Versioning**: Enabled on all artifact and log buckets
- **Bucket Naming**: Includes environment and account ID for uniqueness
- **Deletion Protection**: KMS keys have 10-day deletion window

## CI/CD Security Gates

- **tfsec**: Static analysis for Terraform security issues
- **Checkov**: Policy-as-code security and compliance scanning
- **terraform-compliance**: BDD-style compliance testing
- **Automated Blocking**: Pipeline fails if security checks don't pass

## IAM & Identity

- **Least Privilege**: Placeholder for future IAM role implementation
- **Service Control Policies**: Planned for organizational guardrails
- **GitHub Actions**: Uses OIDC for temporary credentials (no long-lived keys)

## Network Security

- **VPC Isolation**: Dedicated VPC per environment with non-overlapping CIDRs
- **DNS Support**: Enabled for internal name resolution
- **Future Expansion**: Ready for subnet segmentation and security groups
