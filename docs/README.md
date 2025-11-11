# AWS Secure Foundation

## Overview

This Terraform project provides a secure baseline infrastructure for AWS environments. It deploys:

- **VPC**: Isolated network environment with DNS support
- **KMS**: Encryption keys with automatic rotation enabled
- **S3 Secure Buckets**: Private buckets with KMS encryption and versioning
- **CloudTrail**: Multi-region audit logging to dedicated S3 bucket
- **IAM Baseline**: Placeholder for IAM roles and service control policies

The foundation follows AWS security best practices with encryption at rest, audit logging, and infrastructure as code compliance checks.

## Prerequisites

- Terraform >= 1.6
- AWS CLI configured with appropriate credentials
- AWS account with sufficient permissions
- S3 bucket and DynamoDB table for remote state (already configured)

## Supported Region

- **eu-central-1** (Frankfurt)

## Getting Started

### Initialize Terraform

Navigate to your desired environment directory:

```bash
cd environments/prod
terraform init
```

This will configure the S3 backend and download required providers.

### Plan Changes

Review the infrastructure changes before applying:

```bash
terraform plan -var-file=tfvars.example
```

### Apply Infrastructure

Deploy the infrastructure:

```bash
terraform apply -var-file=tfvars.example
```

Review the plan output and type `yes` to confirm.

### Destroy Infrastructure

To tear down all resources:

```bash
terraform destroy -var-file=tfvars.example
```

**Warning**: This will delete all resources including CloudTrail logs and encrypted data.

## Cost Considerations

Estimated monthly costs for this foundation (eu-central-1):

- **VPC**: Free (no NAT gateways or data transfer yet)
- **KMS**: ~$1/month per key
- **S3 Storage**: ~$0.023/GB (varies by usage)
- **CloudTrail**: First trail free, S3 storage charges apply
- **DynamoDB (state lock)**: ~$0.25/month (on-demand pricing)

**Total estimated cost**: $5-15/month depending on storage and API usage.

## Environments

- `dev`: Development environment (CIDR: 10.12.0.0/16)
- `staging`: Staging environment (CIDR: 10.11.0.0/16)
- `prod`: Production environment (CIDR: 10.10.0.0/16)

## Security & Compliance

This project includes:
- Automated security scanning (tfsec, Checkov)
- Compliance validation (terraform-compliance)
- Encryption at rest for all data stores
- CloudTrail audit logging
- Public access blocking on all S3 buckets

## Next Steps

See additional documentation:
- [Security Decisions](./security-decisions.md)
- [Audit Log Access](./audit-log-access.md)
- [Runbook](./runbook.md)
