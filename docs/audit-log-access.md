# Audit Log Access

## Overview

This document describes how to grant read-only access to CloudTrail audit logs without allowing modification or deletion. This is essential for security auditors, compliance teams, and incident responders.

## Access Requirements

Audit log access typically requires two components:

1. **CloudTrail Lookup**: Query CloudTrail events via API/Console
2. **S3 Bucket Access**: Read raw CloudTrail logs from S3

## IAM Policy: CloudTrail Read-Only

Grant read-only access to CloudTrail without allowing trail modification:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "CloudTrailReadOnly",
      "Effect": "Allow",
      "Action": [
        "cloudtrail:LookupEvents",
        "cloudtrail:GetTrail",
        "cloudtrail:GetTrailStatus",
        "cloudtrail:GetEventSelectors",
        "cloudtrail:ListTrails",
        "cloudtrail:DescribeTrails"
      ],
      "Resource": "*"
    }
  ]
}
```

## IAM Policy: S3 Logs Bucket Read-Only

Grant read access to the CloudTrail logs bucket:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "ListCloudTrailBucket",
      "Effect": "Allow",
      "Action": [
        "s3:ListBucket",
        "s3:GetBucketLocation",
        "s3:GetBucketVersioning"
      ],
      "Resource": "arn:aws:s3:::logs-${ENV}-${ACCOUNT_ID}"
    },
    {
      "Sid": "ReadCloudTrailLogs",
      "Effect": "Allow",
      "Action": [
        "s3:GetObject",
        "s3:GetObjectVersion"
      ],
      "Resource": "arn:aws:s3:::logs-${ENV}-${ACCOUNT_ID}/*"
    }
  ]
}
```

**Note**: Replace `${ENV}` and `${ACCOUNT_ID}` with actual values (e.g., `logs-prod-123456789012`).

## Combined Policy: Audit Access Role

Complete IAM policy for audit access:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "CloudTrailReadOnly",
      "Effect": "Allow",
      "Action": [
        "cloudtrail:LookupEvents",
        "cloudtrail:GetTrail",
        "cloudtrail:GetTrailStatus",
        "cloudtrail:GetEventSelectors",
        "cloudtrail:ListTrails",
        "cloudtrail:DescribeTrails"
      ],
      "Resource": "*"
    },
    {
      "Sid": "ListCloudTrailBucket",
      "Effect": "Allow",
      "Action": [
        "s3:ListBucket",
        "s3:GetBucketLocation",
        "s3:GetBucketVersioning"
      ],
      "Resource": "arn:aws:s3:::logs-*"
    },
    {
      "Sid": "ReadCloudTrailLogs",
      "Effect": "Allow",
      "Action": [
        "s3:GetObject",
        "s3:GetObjectVersion"
      ],
      "Resource": "arn:aws:s3:::logs-*/*"
    }
  ]
}
```

## Creating an Auditor Role

### Step 1: Create IAM Role

```bash
aws iam create-role \
  --role-name CloudTrailAuditor \
  --assume-role-policy-document file://trust-policy.json
```

**trust-policy.json**:
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "AWS": "arn:aws:iam::AUDITOR_ACCOUNT_ID:root"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
```

### Step 2: Attach Policy

```bash
aws iam put-role-policy \
  --role-name CloudTrailAuditor \
  --policy-name AuditLogAccess \
  --policy-document file://audit-policy.json
```

### Step 3: Grant Access to Users

Users in the auditor account can assume the role:

```bash
aws sts assume-role \
  --role-arn arn:aws:iam::062266257890:role/CloudTrailAuditor \
  --role-session-name audit-session
```

## Accessing Logs via AWS CLI

### Lookup Recent Events

```bash
aws cloudtrail lookup-events \
  --lookup-attributes AttributeKey=EventName,AttributeValue=PutObject \
  --max-results 50
```

### Download Log Files

```bash
aws s3 cp s3://logs-prod-123456789012/AWSLogs/ . --recursive
```

## Best Practices

- **Separate Auditor Account**: Use cross-account roles for auditors
- **MFA Required**: Enforce MFA for assuming auditor roles
- **Session Duration**: Limit role session duration (e.g., 1-4 hours)
- **Logging**: Enable CloudTrail for auditor account access
- **Regular Reviews**: Audit who has access to audit logs quarterly

## Denied Actions

The read-only policy explicitly **does not** allow:

- `cloudtrail:StopLogging`
- `cloudtrail:DeleteTrail`
- `cloudtrail:UpdateTrail`
- `s3:PutObject`
- `s3:DeleteObject`
- `s3:DeleteBucket`

This ensures audit logs remain tamper-proof.
