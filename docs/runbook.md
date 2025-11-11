# Operational Runbook

## Daily Operations

### Terraform Plan

Review infrastructure changes before applying:

```bash
cd environments/prod
terraform plan -var-file=tfvars.example
```

**Expected behavior**: Plan completes without errors, shows resource changes.

**Troubleshooting**:
- If backend init fails, verify S3 bucket and DynamoDB table exist
- If validation fails, check module variable definitions
- If provider auth fails, verify AWS credentials are configured

### Terraform Apply

Deploy approved infrastructure changes:

```bash
cd environments/prod
terraform apply -var-file=tfvars.example
```

**Pre-apply checklist**:
- [ ] Plan output reviewed and approved
- [ ] Change ticket created and linked
- [ ] Backup state file exists
- [ ] Team notified of deployment window

**Post-apply verification**:
- [ ] Resources created successfully
- [ ] CloudTrail logging active
- [ ] KMS keys accessible
- [ ] S3 buckets encrypted

### Rollback Procedure

If a deployment causes issues, rollback using previous state:

#### Option 1: Targeted Resource Replacement

```bash
# Revert specific resource to previous configuration
terraform apply -replace="module.kms.aws_kms_key.main"
```

#### Option 2: Full State Rollback

```bash
# 1. List state versions
aws s3api list-object-versions \
  --bucket chiamaka-tf-state-1762851626.57447 \
  --prefix aws-secure-foundation/prod/terraform.tfstate

# 2. Download previous version
aws s3api get-object \
  --bucket chiamaka-tf-state-1762851626.57447 \
  --key aws-secure-foundation/prod/terraform.tfstate \
  --version-id PREVIOUS_VERSION_ID \
  terraform.tfstate.backup

# 3. Apply rollback
terraform apply -state=terraform.tfstate.backup
```

**Warning**: State rollback should be last resort. Prefer reverting code changes.

## KMS Key Management

### Check Key Rotation Status

```bash
# Get KMS key ID from Terraform output
KEY_ID=$(terraform output -raw module.kms.key_id)

# Check rotation status
aws kms get-key-rotation-status --key-id $KEY_ID
```

**Expected output**:
```json
{
    "KeyRotationEnabled": true
}
```

### Manual Key Rotation

KMS keys rotate automatically every 365 days. To force immediate rotation:

```bash
# Disable and re-enable rotation
aws kms disable-key-rotation --key-id $KEY_ID
aws kms enable-key-rotation --key-id $KEY_ID
```

**Note**: Automatic rotation is preferred. Manual rotation should only be used during security incidents.

### Verify Key Usage

```bash
# List aliases
aws kms list-aliases

# Describe key
aws kms describe-key --key-id $KEY_ID
```

## S3 Object Recovery

### List Object Versions

```bash
BUCKET_NAME="secure-prod-artifacts-abc123"

aws s3api list-object-versions \
  --bucket $BUCKET_NAME \
  --prefix path/to/file.txt
```

### Restore Previous Version

```bash
# Get version ID from list-object-versions output
VERSION_ID="ABC123XYZ"

# Copy old version to current
aws s3api copy-object \
  --bucket $BUCKET_NAME \
  --copy-source "$BUCKET_NAME/path/to/file.txt?versionId=$VERSION_ID" \
  --key path/to/file.txt
```

### Restore Deleted Object

```bash
# Find delete marker
aws s3api list-object-versions \
  --bucket $BUCKET_NAME \
  --prefix path/to/deleted-file.txt

# Remove delete marker
aws s3api delete-object \
  --bucket $BUCKET_NAME \
  --key path/to/deleted-file.txt \
  --version-id DELETE_MARKER_VERSION_ID
```

## CloudTrail Monitoring

### Verify Trail Status

```bash
aws cloudtrail get-trail-status --name cloudtrail-prod
```

**Expected output**:
```json
{
    "IsLogging": true,
    "LatestDeliveryTime": "2025-11-11T10:30:00Z"
}
```

### Query Recent Events

```bash
# Last 24 hours of KMS key usage
aws cloudtrail lookup-events \
  --lookup-attributes AttributeKey=ResourceType,AttributeValue=AWS::KMS::Key \
  --start-time $(date -u -d '24 hours ago' +%Y-%m-%dT%H:%M:%S) \
  --max-results 50
```

### Check for Security Events

```bash
# Failed authentication attempts
aws cloudtrail lookup-events \
  --lookup-attributes AttributeKey=EventName,AttributeValue=ConsoleLogin \
  --max-results 100 \
  | jq '.Events[] | select(.CloudTrailEvent | contains("Failure"))'
```

## Break-Glass Access

### Emergency Access Principles

In security incidents requiring immediate access:

1. **Least Privilege**: Grant only minimum permissions needed
2. **Time-Bound**: Set expiration on emergency access (max 4 hours)
3. **Logged**: All break-glass access must be logged and reviewed
4. **Revoked**: Remove access immediately after incident resolution
5. **Documented**: Record reason, actions taken, and resolution

### Emergency IAM Policy

Create temporary policy for incident response:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "EmergencyReadAccess",
      "Effect": "Allow",
      "Action": [
        "cloudtrail:LookupEvents",
        "s3:GetObject",
        "s3:ListBucket",
        "kms:Decrypt",
        "logs:FilterLogEvents"
      ],
      "Resource": "*",
      "Condition": {
        "DateLessThan": {
          "aws:CurrentTime": "2025-11-11T14:00:00Z"
        }
      }
    }
  ]
}
```

### Break-Glass Role Creation

```bash
# 1. Create role with MFA requirement
aws iam create-role \
  --role-name EmergencyAccess \
  --assume-role-policy-document file://break-glass-trust.json

# 2. Attach time-bound policy
aws iam put-role-policy \
  --role-name EmergencyAccess \
  --policy-name EmergencyIncidentResponse \
  --policy-document file://emergency-policy.json

# 3. Assume role with MFA
aws sts assume-role \
  --role-arn arn:aws:iam::ACCOUNT_ID:role/EmergencyAccess \
  --role-session-name incident-response \
  --duration-seconds 14400 \
  --serial-number arn:aws:iam::ACCOUNT_ID:mfa/USER \
  --token-code MFA_CODE
```

**break-glass-trust.json**:
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "AWS": "arn:aws:iam::ACCOUNT_ID:root"
      },
      "Action": "sts:AssumeRole",
      "Condition": {
        "Bool": {
          "aws:MultiFactorAuthPresent": "true"
        }
      }
    }
  ]
}
```

### Post-Incident Cleanup

```bash
# 1. Revoke emergency access
aws iam delete-role-policy \
  --role-name EmergencyAccess \
  --policy-name EmergencyIncidentResponse

aws iam delete-role --role-name EmergencyAccess

# 2. Review CloudTrail logs
aws cloudtrail lookup-events \
  --lookup-attributes AttributeKey=Username,AttributeValue=incident-response

# 3. Document incident
# - What happened
# - What access was granted
# - What actions were taken
# - Remediation steps
```

## Disaster Recovery

### State File Backup

State files are versioned in S3. To create manual backup:

```bash
aws s3 cp \
  s3://chiamaka-tf-state-1762851626.57447/aws-secure-foundation/prod/terraform.tfstate \
  ./backups/terraform.tfstate.$(date +%Y%m%d-%H%M%S)
```

### Complete Infrastructure Recovery

```bash
# 1. Clone repository
git clone <repo-url>
cd aws-secure-foundation

# 2. Initialize backend
cd environments/prod
terraform init

# 3. Import existing resources (if needed)
terraform import module.kms.aws_kms_key.main <key-id>

# 4. Apply from scratch
terraform apply -var-file=tfvars.example
```

## Monitoring & Alerts

### Key Metrics to Monitor

- CloudTrail: `IsLogging` status
- S3 Buckets: Encryption status, versioning enabled
- KMS Keys: Key rotation enabled, key state = Enabled
- Terraform State: Lock status, last modified timestamp

### Alert Thresholds

- CloudTrail logging stopped: **Immediate P1 alert**
- KMS key disabled: **Immediate P1 alert**
- Failed authentication attempts > 10/hour: **P2 alert**
- S3 public access enabled: **Immediate P1 alert**

## Contact Information

- **Security Team**: security@example.com
- **On-Call**: PagerDuty integration
- **Escalation**: CTO / CISO

## Compliance & Audit

- Run compliance checks before each deployment
- Review CloudTrail logs weekly
- Quarterly access reviews for all IAM roles
- Annual security assessment and penetration testing
