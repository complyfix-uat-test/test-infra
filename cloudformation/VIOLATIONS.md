# CloudFormation Test Corpus — Detailed Violation Map

This document maps each compliance violation in the MedVault CloudFormation templates to exact file locations, line numbers (estimated), and expected Checkov check IDs.

## Violation Index by Pattern

---

## Pattern 1: S3 Bucket Missing Encryption

**File:** `data-tier.json`  
**Resource:** `PHIStorageBucket`  
**Issue:** Missing `ServerSideEncryptionConfiguration` block

**JSON Structure:**
```json
{
  "Type": "AWS::S3::Bucket",
  "Properties": {
    "BucketName": { "Fn::Sub": "medvault-phi-${Environment}-${AWS::AccountId}" },
    "Tags": [ ... ]
  }
}
```

**Fix:** Add ServerSideEncryptionConfiguration:
```json
"ServerSideEncryptionConfiguration": [
  {
    "ServerSideEncryptionByDefault": {
      "SSEAlgorithm": "AES256"
    }
  }
]
```

**Checkov Checks:**
- CKV_AWS_34: Ensure S3 bucket has encryption enabled
- CKV_AWS_345: Ensure S3 bucket has encryption enabled (alternative)

**Severity:** MEDIUM → HIGH (stores PHI)

---

## Pattern 2: S3 Bucket Missing Versioning

**File:** `data-tier.json`  
**Resource:** `PHIStorageBucket`  
**Issue:** Missing `VersioningConfiguration`

**JSON Structure:**
```json
{
  "Type": "AWS::S3::Bucket",
  "Properties": {
    "BucketName": "...",
    "Tags": [ ... ]
    /* VersioningConfiguration is absent */
  }
}
```

**Fix:** Add VersioningConfiguration:
```json
"VersioningConfiguration": {
  "Status": "Enabled"
}
```

**Checkov Checks:**
- CKV_AWS_33: Ensure S3 bucket has versioning enabled

**Severity:** MEDIUM

---

## Pattern 3: S3 Bucket Missing Public Access Block

**File:** `data-tier.json`  
**Resources:** 
1. `PHIStorageBucket` — missing `PublicAccessBlockConfiguration`
2. `StaticAssetsBucket` — missing `PublicAccessBlockConfiguration` AND has bucket policy allowing public read

**PHI Bucket Fix:**
```json
"PublicAccessBlockConfiguration": {
  "BlockPublicAcls": true,
  "BlockPublicPolicy": true,
  "IgnorePublicAcls": true,
  "RestrictPublicBuckets": true
}
```

**Static Assets Bucket Issue:** Has `StaticAssetsBucketPolicy` allowing `s3:GetObject` for principal `"*"`:
```json
{
  "Sid": "PublicReadGetObject",
  "Effect": "Allow",
  "Principal": "*",
  "Action": "s3:GetObject",
  "Resource": "${StaticAssetsBucket.Arn}/*"
}
```

**Checkov Checks:**
- CKV_AWS_144: Ensure that S3 bucket has public access block enabled
- CKV2_AWS_6: Ensure S3 bucket has public access block (alternative)

**Severity:** MEDIUM (public read) → HIGH (if PHI)

---

## Pattern 4: S3 Bucket Missing Logging

**File:** `data-tier.json`  
**Resource:** `PHIStorageBucket`  
**Issue:** Missing `LoggingConfiguration` block

**JSON Structure:**
```json
{
  "Type": "AWS::S3::Bucket",
  "Properties": {
    "BucketName": "...",
    "ServerSideEncryptionConfiguration": [ ... ],
    "Tags": [ ... ]
    /* LoggingConfiguration is absent */
  }
}
```

**Fix:** Add LoggingConfiguration:
```json
"LoggingConfiguration": {
  "DestinationBucketName": { "Ref": "AuditLogsBucket" },
  "LogFilePrefix": "phi-bucket-logs/"
}
```

**Checkov Checks:**
- CKV_AWS_143: Ensure S3 bucket has logging enabled

**Severity:** MEDIUM

---

## Pattern 5: Security Group Allows SSH from 0.0.0.0/0

**File:** `networking.yaml`  
**Resource:** `BastionSecurityGroup`  
**Line:** Approximately line 230-245 (SecurityGroupIngress block)

**YAML Structure:**
```yaml
BastionSecurityGroup:
  Type: AWS::EC2::SecurityGroup
  Properties:
    GroupDescription: Security group for bastion host
    VpcId: !Ref MedVaultVPC
    SecurityGroupIngress:
      - IpProtocol: tcp
        FromPort: 22
        ToPort: 22
        CidrIp: 0.0.0.0/0          # VIOLATION: Unrestricted SSH
        Description: SSH access from anywhere - VIOLATION
```

**Fix:** Restrict CIDR (e.g., corporate network or specific office):
```yaml
CidrIp: 203.0.113.0/24  # Example: corporate network
```

**Checkov Checks:**
- CKV_AWS_24: Ensure no security groups allow ingress from 0.0.0.0/0 to port 22
- CKV_AWS_21: Ensure no security groups allow ingress from 0.0.0.0:0 to port 22

**Severity:** CRITICAL

---

## Pattern 6: Security Group Allows RDP from 0.0.0.0/0

**File:** `networking.yaml`  
**Resource:** `LegacyWindowsSecurityGroup`  
**Line:** Approximately line 250-265 (SecurityGroupIngress block)

**YAML Structure:**
```yaml
LegacyWindowsSecurityGroup:
  Type: AWS::EC2::SecurityGroup
  Properties:
    GroupDescription: Security group for legacy Windows servers
    VpcId: !Ref MedVaultVPC
    SecurityGroupIngress:
      - IpProtocol: tcp
        FromPort: 3389
        ToPort: 3389
        CidrIp: 0.0.0.0/0          # VIOLATION: Unrestricted RDP
        Description: RDP access from anywhere - VIOLATION
```

**Fix:** Restrict to admin workstations:
```yaml
CidrIp: 192.168.1.0/24  # Example: admin network
```

**Checkov Checks:**
- CKV_AWS_25: Ensure no security groups allow ingress from 0.0.0.0/0 to port 3389

**Severity:** CRITICAL

---

## Pattern 7: RDS Not Encrypted

**File:** `data-tier.json`  
**Resource:** `RDSPostgresInstance`  
**Property:** `StorageEncrypted`

**JSON Structure:**
```json
{
  "Type": "AWS::RDS::DBInstance",
  "Properties": {
    "DBInstanceIdentifier": "medvault-postgres-staging",
    "Engine": "postgres",
    "StorageEncrypted": false,    # VIOLATION: Not encrypted
    "PubliclyAccessible": true,
    "..."
  }
}
```

**Fix:** Enable encryption:
```json
"StorageEncrypted": true,
"KmsKeyId": "arn:aws:kms:us-east-1:123456789012:key/12345678-1234-1234-1234-123456789012"
```

**Checkov Checks:**
- CKV_AWS_17: Ensure RDS is encrypted

**Severity:** CRITICAL (PHI database)

---

## Pattern 8: RDS Publicly Accessible

**File:** `data-tier.json`  
**Resource:** `RDSPostgresInstance`  
**Property:** `PubliclyAccessible`

**JSON Structure:**
```json
{
  "Type": "AWS::RDS::DBInstance",
  "Properties": {
    "DBInstanceIdentifier": "medvault-postgres-staging",
    "PubliclyAccessible": true,   # VIOLATION: Exposed to internet
    "..."
  }
}
```

**Fix:** Disable public access:
```json
"PubliclyAccessible": false
```

**Checkov Checks:**
- CKV_AWS_16: Ensure RDS database is not publicly accessible

**Severity:** CRITICAL

---

## Pattern 10: CloudTrail Disabled

**File:** `security.yaml`  
**Resource:** `MedVaultCloudTrail`  
**Issue:** Trail created conditionally; default parameter `EnableCloudTrail: 'false'`

**YAML Structure:**
```yaml
Parameters:
  EnableCloudTrail:
    Type: String
    Default: 'false'              # VIOLATION: CloudTrail disabled by default
    AllowedValues:
      - 'true'
      - 'false'

Conditions:
  CreateCloudTrail: !Equals [!Ref EnableCloudTrail, 'true']

Resources:
  MedVaultCloudTrail:
    Type: AWS::CloudTrail::Trail
    Condition: CreateCloudTrail   # VIOLATION: Not created by default
    # ...
```

**Fix 1 - Change default:**
```yaml
Default: 'true'
```

**Fix 2 - Create trail unconditionally:**
```yaml
# Remove Condition clause, always create
```

**Checkov Checks:**
- CKV_AWS_26: Ensure CloudTrail log file validation is enabled
- CKV_AWS_36: Ensure CloudTrail log file validation is enabled (alternative)
- CKV_AWS_40: Ensure CloudTrail encryption is enabled

**Severity:** HIGH

---

## Pattern 11: IAM Policies Too Permissive (4 violations)

### 11a: Admin Role with "*" Actions and Resources

**File:** `security.yaml`  
**Resource:** `AdminRole`  
**Line:** Policy statement

**YAML Structure:**
```yaml
AdminRole:
  Type: AWS::IAM::Role
  Properties:
    Policies:
      - PolicyName: AdministratorAccess
        PolicyDocument:
          Statement:
            - Effect: Allow
              Action: '*'           # VIOLATION: Allows all actions
              Resource: '*'         # VIOLATION: On all resources
              Sid: VIOLATION: Overly permissive admin policy
```

**Fix:** Use managed policy or restrict actions/resources:
```yaml
ManagedPolicyArns:
  - 'arn:aws:iam::aws:policy/PowerUserAccess'
```

**Checkov Checks:**
- CKV_AWS_40: Ensure IAM policies do not allow full "*" permissions
- CKV_AWS_49: Ensure no IAM policies documents allow "*" as statement's actions or resources
- CKV_AWS_43: Detect the use of implicit * IAM policies

---

### 11b: ECS Task Role with "*" Actions and Resources

**File:** `compute.yaml`  
**Resource:** `ECSTaskRole`  
**Line:** Policy statement

**YAML Structure:**
```yaml
ECSTaskRole:
  Type: AWS::IAM::Role
  Properties:
    Policies:
      - PolicyName: ApplicationPolicy
        PolicyDocument:
          Statement:
            - Effect: Allow
              Action: '*'           # VIOLATION
              Resource: '*'         # VIOLATION
              Sid: VIOLATION: Overly permissive policy
```

**Fix:** Restrict to required AWS services:
```yaml
Action:
  - 's3:GetObject'
  - 's3:PutObject'
  - 'dynamodb:Query'
  - 'dynamodb:PutItem'
Resource:
  - 'arn:aws:s3:::medvault-phi-*/*'
  - 'arn:aws:dynamodb:*:*:table/medvault-*'
```

---

### 11c: Lambda Execution Role with Broad S3 Permissions

**File:** `compute.yaml`  
**Resource:** `LambdaExecutionRole`  
**Line:** S3Access policy

**YAML Structure:**
```yaml
LambdaExecutionRole:
  Type: AWS::IAM::Role
  Properties:
    Policies:
      - PolicyName: S3Access
        PolicyDocument:
          Statement:
            - Effect: Allow
              Action: 's3:*'        # VIOLATION: All S3 actions
              Resource: '*'         # VIOLATION: All buckets
              Sid: VIOLATION: Overly broad S3 permissions
```

**Fix:** Restrict to specific buckets and actions:
```yaml
Action:
  - 's3:GetObject'
  - 's3:PutObject'
Resource:
  - 'arn:aws:s3:::medvault-phi-staging/*'
  - 'arn:aws:s3:::medvault-audit-logs-staging/*'
```

---

### 11d: CI/CD Role Allows AssumeRole with No Conditions

**File:** `security.yaml`  
**Resource:** `CICDRole`  
**Line:** AssumeRolePolicyDocument, second statement

**YAML Structure:**
```yaml
CICDRole:
  Type: AWS::IAM::Role
  Properties:
    AssumeRolePolicyDocument:
      Statement:
        - Effect: Allow
          Principal:
            Service: codepipeline.amazonaws.com
          Action: 'sts:AssumeRole'
        - Effect: Allow
          Principal:
            AWS: !Sub 'arn:aws:iam::${AWS::AccountId}:root'
          Action: 'sts:AssumeRole'
          Sid: VIOLATION: No conditions on AssumeRole  # VIOLATION
```

**Fix:** Add trust conditions:
```yaml
- Effect: Allow
  Principal:
    AWS: !Sub 'arn:aws:iam::${AWS::AccountId}:user/cicd-user'
  Action: 'sts:AssumeRole'
  Condition:
    StringEquals:
      'sts:ExternalId': 'unique-external-id'
    IpAddress:
      'aws:SourceIp':
        - '203.0.113.0/24'  # CI/CD agent IP range
```

**Checkov Checks:**
- CKV_AWS_40: Ensure IAM policies do not allow full "*" permissions
- CKV_AWS_49: Ensure no IAM policies documents allow "*" as statement's actions or resources

**Severity:** CRITICAL (all 4 violations)

---

## Pattern 17: ALB Without HTTPS Listener

**File:** `compute.yaml`  
**Resource:** `ApplicationLoadBalancer` + listener configuration  
**Issue:** HTTP listener exists; HTTPS listener conditional (default not created)

**YAML Structure:**
```yaml
HTTPListener:
  Type: AWS::ElasticLoadBalancingV2::Listener
  Properties:
    LoadBalancerArn: !Ref ApplicationLoadBalancer
    Port: 80
    Protocol: HTTP              # VIOLATION: HTTP only
    DefaultActions:
      - Type: forward
        TargetGroupArn: !Ref ApplicationTargetGroup

HTTPSListener:
  Type: AWS::ElasticLoadBalancingV2::Listener
  Condition: HasCertificate    # VIOLATION: Only created if certificate provided
  Properties:
    Port: 443
    Protocol: HTTPS
```

**Fix:** Require HTTPS listener:
```yaml
HTTPSListener:
  Type: AWS::ElasticLoadBalancingV2::Listener
  # Remove Condition to always create
  Properties:
    Port: 443
    Protocol: HTTPS
    Certificates:
      - CertificateArn: 'arn:aws:acm:us-east-1:...'  # Provide default
```

**Checkov Checks:**
- CKV_AWS_5: Ensure ALB/NLB has HTTPS listener

**Severity:** MEDIUM → HIGH (depends on data sensitivity)

---

## Pattern 18: RDS Without Backup Retention

**File:** `data-tier.json`  
**Resource:** `RDSPostgresInstance`  
**Property:** `BackupRetentionPeriod`

**JSON Structure:**
```json
{
  "Type": "AWS::RDS::DBInstance",
  "Properties": {
    "BackupRetentionPeriod": 0,   # VIOLATION: No backups
    "..."
  }
}
```

**Fix:** Enable backup retention:
```json
"BackupRetentionPeriod": 7,
"PreferredBackupWindow": "03:00-04:00"
```

**Checkov Checks:**
- CKV_AWS_35: Ensure RDS has backup retention enabled

**Severity:** MEDIUM

---

## Pattern 19: RDS Not Multi-AZ

**File:** `data-tier.json`  
**Resource:** `RDSPostgresInstance`  
**Property:** `MultiAZ`

**JSON Structure:**
```json
{
  "Type": "AWS::RDS::DBInstance",
  "Properties": {
    "MultiAZ": false,            # VIOLATION: Single AZ
    "..."
  }
}
```

**Fix:** Enable Multi-AZ:
```json
"MultiAZ": true
```

**Checkov Checks:**
- CKV_AWS_31: Ensure RDS database has Multi-AZ deployment enabled

**Severity:** MEDIUM (availability)

---

## Pattern 20: CloudWatch Log Groups Without Retention (2 violations)

**File:** `security.yaml`  
**Resources:**
1. `ApplicationLogGroup` — `/medvault/application`
2. `AuditLogGroup` — `/medvault/audit`

**Issue:** Missing or null `RetentionInDays`

**YAML Structure:**
```yaml
ApplicationLogGroup:
  Type: AWS::Logs::LogGroup
  Properties:
    LogGroupName: /medvault/application
    RetentionInDays: null         # VIOLATION: No retention

AuditLogGroup:
  Type: AWS::Logs::LogGroup
  Properties:
    LogGroupName: /medvault/audit
    RetentionInDays: null         # VIOLATION: No retention
```

**Compliant Example (AccessLogGroup):**
```yaml
AccessLogGroup:
  Type: AWS::Logs::LogGroup
  Properties:
    LogGroupName: /medvault/access
    RetentionInDays: 365          # COMPLIANT
```

**Fix:** Set retention period:
```yaml
RetentionInDays: 90
```

**Checkov Checks:**
- CKV_AWS_66: Ensure CloudWatch log groups are retained for more than 1 day
- CKV_AWS_63: Ensure that CloudWatch log group is encrypted by KMS (secondary)

**Severity:** MEDIUM

---

## Pattern 21: VPC Without Flow Logs

**File:** `networking.yaml`  
**Resource:** `VPCFlowLogs`  
**Issue:** Flow logs resource created conditionally; default parameter `EnableFlowLogs: 'false'`

**YAML Structure:**
```yaml
Parameters:
  EnableFlowLogs:
    Type: String
    Default: 'false'              # VIOLATION: Disabled by default
    AllowedValues:
      - 'true'
      - 'false'

Conditions:
  CreateFlowLogs: !Equals [!Ref EnableFlowLogs, 'true']

Resources:
  VPCFlowLogs:
    Type: AWS::EC2::FlowLog
    Condition: CreateFlowLogs     # VIOLATION: Not created by default
```

**Fix:** Enable by default:
```yaml
Default: 'true'
```

**Checkov Checks:**
- CKV_AWS_62: Ensure VPC Flow logs is enabled for every subnet in VPC

**Severity:** MEDIUM

---

## Pattern 22: MFA Not Enforced

**File:** `security.yaml`  
**Resource:** `MFAEnforcement`  
**Issue:** MFA policy exists but is ineffective (deny policy without actual requirement)

**YAML Structure:**
```yaml
MFAEnforcement:
  Type: AWS::IAM::Policy
  Properties:
    PolicyName: MFAEnforcementPolicy
    PolicyDocument:
      Statement:
        - Sid: VIOLATION: MFA not required
          Effect: Deny
          Action:
            - 'iam:DeleteAccessKey'
            - 'iam:DeleteLoginProfile'
            - 'iam:DeleteVirtualMFADevice'
```

**Fix:** Implement actual MFA enforcement:
```yaml
- Sid: RequireMFAForSensitiveActions
  Effect: Deny
  Action:
    - 's3:DeleteBucket'
    - 'iam:DeleteUser'
    - 'iam:DeleteRole'
    - 'rds:DeleteDBInstance'
  Resource: '*'
  Condition:
    BoolIfExists:
      'aws:MultiFactorAuthPresent': false
```

**Checkov Checks:**
- CKV_AWS_23: Ensure every IAM policy has MFA requirement

**Severity:** MEDIUM

---

## Pattern 24: ECR Without Image Scanning

**File:** `compute.yaml`  
**Resource:** `MedVaultECRRepository`  
**Property:** `ImageScanningConfiguration`

**YAML Structure:**
```yaml
MedVaultECRRepository:
  Type: AWS::ECR::Repository
  Properties:
    RepositoryName: medvault-app-staging
    ImageScanningConfiguration:
      ScanOnPush: false           # VIOLATION: Scanning disabled
```

**Fix:** Enable scanning:
```yaml
ImageScanningConfiguration:
  ScanOnPush: true
```

**Checkov Checks:**
- CKV_AWS_222: Ensure ECR image scanning on push is enabled

**Severity:** MEDIUM

---

## Pattern 25: Lambda Without VPC Config (2 violations)

### 25a: DataProcessorFunction

**File:** `compute.yaml`  
**Resource:** `DataProcessorFunction`  
**Issue:** Missing `VpcConfig` block

**YAML Structure:**
```yaml
DataProcessorFunction:
  Type: AWS::Lambda::Function
  Properties:
    FunctionName: medvault-data-processor-staging
    Runtime: python3.11
    Handler: index.handler
    Role: !GetAtt LambdaExecutionRole.Arn
    Timeout: 300
    MemorySize: 512
    # VpcConfig is missing    # VIOLATION
    Code:
      ZipFile: |
        ...
```

**Fix:** Add VpcConfig:
```yaml
VpcConfig:
  SecurityGroupIds:
    - !ImportValue MedVault-AppSG-staging
  SubnetIds:
    - !Select [0, !Split [',', !ImportValue 'MedVault-PrivateSubnets-staging']]
    - !Select [1, !Split [',', !ImportValue 'MedVault-PrivateSubnets-staging']]
```

---

### 25b: NotificationFunction

**File:** `compute.yaml`  
**Resource:** `NotificationFunction`  
**Issue:** Missing `VpcConfig` block

**YAML Structure:**
```yaml
NotificationFunction:
  Type: AWS::Lambda::Function
  Properties:
    FunctionName: medvault-notification-staging
    Runtime: python3.11
    Handler: index.handler
    # VpcConfig is missing    # VIOLATION
    Code:
      ZipFile: |
        ...
```

**Compliant Example (AuditLogFunction):**
```yaml
AuditLogFunction:
  Type: AWS::Lambda::Function
  Properties:
    FunctionName: medvault-audit-log-staging
    VpcConfig:
      SecurityGroupIds:
        - !ImportValue MedVault-AppSG-staging
      SubnetIds:
        - !Select [0, !Split [',', !ImportValue 'MedVault-PrivateSubnets-staging']]
```

**Checkov Checks:**
- CKV_AWS_210: Ensure Lambda function is created inside a VPC

**Severity:** MEDIUM

---

## Pattern 26: DynamoDB Without Encryption

**File:** `data-tier.json`  
**Resource:** `DynamoDBSessionsTable`  
**Issue:** Missing `SSESpecification` block

**JSON Structure:**
```json
{
  "Type": "AWS::DynamoDB::Table",
  "Properties": {
    "TableName": "medvault-sessions-staging",
    "BillingMode": "PAY_PER_REQUEST",
    "AttributeDefinitions": [ ... ],
    "KeySchema": [ ... ],
    "TimeToLiveSpecification": { ... },
    "Tags": [ ... ]
    /* SSESpecification is missing */    # VIOLATION
  }
}
```

**Compliant Example (DynamoDBAllAuditTrailTable):**
```json
{
  "Type": "AWS::DynamoDB::Table",
  "Properties": {
    "TableName": "medvault-audit-trail-staging",
    "SSESpecification": {
      "SSEEnabled": true,
      "SSEType": "KMS",
      "KMSMasterKeyId": "arn:aws:kms:us-east-1:123456789012:key/..."
    },
    "PointInTimeRecoverySpecification": {
      "PointInTimeRecoveryEnabled": true
    }
  }
}
```

**Fix:** Add SSESpecification:
```json
"SSESpecification": {
  "SSEEnabled": true,
  "SSEType": "KMS"
}
```

**Checkov Checks:**
- CKV_AWS_28: Ensure DynamoDB encryption is enabled
- CKV_AWS_272: Ensure DynamoDB point-in-time recovery (backup) is enabled (secondary)

**Severity:** HIGH (session data can contain user tokens)

---

## Pattern 30: SNS Topics Without KMS Encryption (2 violations)

### 30a: MedVaultAlertsTopic

**File:** `security.yaml`  
**Resource:** `MedVaultAlertsTopic`  
**Issue:** Missing `KmsMasterKeyId` property

**YAML Structure:**
```yaml
MedVaultAlertsTopic:
  Type: AWS::SNS::Topic
  Properties:
    TopicName: medvault-alerts-staging
    DisplayName: MedVault Security Alerts
    Subscription:
      - Endpoint: !Ref AdminEmail
        Protocol: email
    # KmsMasterKeyId is missing    # VIOLATION
    Tags:
      - Key: Compliance
        Value: HIPAA
```

---

### 30b: MedVaultAuditNotificationsTopic

**File:** `security.yaml`  
**Resource:** `MedVaultAuditNotificationsTopic`  
**Issue:** Missing `KmsMasterKeyId` property

**YAML Structure:**
```yaml
MedVaultAuditNotificationsTopic:
  Type: AWS::SNS::Topic
  Properties:
    TopicName: medvault-audit-notifications-staging
    DisplayName: MedVault Audit Notifications
    # KmsMasterKeyId is missing    # VIOLATION
    Tags:
      - Key: Compliance
        Value: HIPAA
```

**Fix:** Add KMS encryption:
```yaml
KmsMasterKeyId: !Ref MedVaultMasterKey
```

**Checkov Checks:**
- CKV_AWS_94: Ensure SNS topics are encrypted

**Severity:** MEDIUM

---

## Additional Violations (Not Top 30 Patterns)

### ElastiCache Redis Without Encryption

**File:** `data-tier.json`  
**Resource:** `RedisCluster`  
**Issue:** Encryption at transit and at rest disabled

**JSON Structure:**
```json
{
  "Type": "AWS::ElastiCache::CacheCluster",
  "Properties": {
    "CacheClusterId": "medvault-redis-staging",
    "Engine": "redis",
    "TransitEncryptionEnabled": false,      # VIOLATION
    "AtRestEncryptionEnabled": false,       # VIOLATION
    "AuthToken": "",                         # VIOLATION: No auth token
    "..."
  }
}
```

**Fix:** Enable encryption:
```json
"TransitEncryptionEnabled": true,
"AtRestEncryptionEnabled": true,
"AuthToken": "SecureAuthToken123456789",
"AutomaticFailoverEnabled": true,
"MultiAZEnabled": true
```

**Severity:** MEDIUM

---

## Summary Statistics

| Metric | Value |
|--------|-------|
| Total Violation Sites | 32 |
| Critical Severity | 6 (patterns 5, 6, 7, 8, 11) |
| High Severity | 6 (patterns 1, 10, 17, 26) |
| Medium Severity | 20 (patterns 2, 3, 4, 18, 19, 20, 21, 22, 24, 25, 30 + ElastiCache) |
| CloudFormation Files | 4 |
| JSON Resources | 10 |
| YAML Resources | ~45 |
| Intrinsic Functions Used | 11 |

---

## Expected Checkov Output

When ComplyFix scans these templates with Checkov, expect approximately **32 findings** across **18 unique check IDs**:

1. CKV_AWS_5 — ALB HTTPS
2. CKV_AWS_16 — RDS public access
3. CKV_AWS_17 — RDS encryption
4. CKV_AWS_24 — SG SSH 0.0.0.0/0
5. CKV_AWS_25 — SG RDP 0.0.0.0/0
6. CKV_AWS_26 — CloudTrail validation
7. CKV_AWS_28 — DynamoDB encryption
8. CKV_AWS_31 — RDS Multi-AZ
9. CKV_AWS_33 — S3 versioning
10. CKV_AWS_34 — S3 encryption
11. CKV_AWS_35 — RDS backup
12. CKV_AWS_40 — IAM * actions
13. CKV_AWS_43 — Implicit * IAM
14. CKV_AWS_49 — * IAM actions/resources
15. CKV_AWS_62 — VPC Flow Logs
16. CKV_AWS_66 — CloudWatch retention
17. CKV_AWS_143 — S3 logging
18. CKV_AWS_144 — S3 public block
19. CKV_AWS_210 — Lambda VPC
20. CKV_AWS_222 — ECR scanning
21. CKV_AWS_272 — DynamoDB PITR
22. CKV2_AWS_6 — S3 public block (v2)
23. CKV_AWS_94 — SNS encryption

---

**Generated:** April 16, 2026  
**For:** ComplyFix CloudFormation Scanner Validation
