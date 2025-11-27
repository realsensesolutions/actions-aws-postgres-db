# AWS Aurora DSQL GitHub Action

[![Test Action](https://github.com/realsensesolutions/actions-aws-postgres-db/actions/workflows/test-action.yml/badge.svg)](https://github.com/realsensesolutions/actions-aws-postgres-db/actions/workflows/test-action.yml)

This GitHub Action creates an AWS Aurora DSQL (Distributed SQL) serverless database cluster using Terraform with backend state management.

## Description

Amazon Aurora DSQL is a serverless, distributed SQL database engineered for high availability, strong consistency, and unlimited scalability. This action provides a **simplified deployment** that:

- Creates an Aurora DSQL cluster with optional deletion protection
- Creates an IAM role for database access (optional)
- Uses public endpoint for connectivity (no VPC endpoints needed)
- Stores Terraform state in S3 with DynamoDB locking

## Prerequisites

### AWS Requirements

- AWS CLI configured or AWS credentials available
- IAM permissions for:
  - DSQL cluster creation (`dsql:*`)
  - IAM role creation (`iam:CreateRole`, `iam:PutRolePolicy`) - if `create_iam_role: true`

### Required Actions

This action requires the Terraform backend to be set up first:

```yaml
- uses: alonch/actions-aws-backend-setup@main
  with:
    instance: my-app
```

### Region Availability

Aurora DSQL is available in select AWS regions. Verify that your target region supports Aurora DSQL before deployment.

## Inputs

| Name | Description | Required | Default |
|------|-------------|----------|---------|
| `name` | Base name for the Aurora DSQL cluster | ✅ | - |
| `action` | Desired outcome: `plan`, `apply`, or `destroy` | ❌ | `apply` |
| `deletion_protection_enabled` | Enable deletion protection for the DSQL cluster | ❌ | `false` |
| `create_iam_role` | Create IAM role for DSQL cluster access | ❌ | `true` |
| `lock-timeout` | Time to wait for Terraform state lock | ❌ | `5m` |

## Outputs

| Name | Description |
|------|-------------|
| `cluster_arn` | ARN of the Aurora DSQL cluster |
| `cluster_id` | ID of the Aurora DSQL cluster |
| `cluster_endpoint` | Public endpoint of the Aurora DSQL cluster |
| `vpc_endpoint_service_name` | VPC endpoint service name (for future VPC endpoint creation) |
| `iam_role_arn` | ARN of the IAM role for DSQL access (if created) |
| `region` | AWS region where the cluster is deployed |

### Environment Variables

Outputs are also exported as environment variables for downstream actions:

- `TF_VAR_dsql_cluster_arn`
- `TF_VAR_dsql_cluster_id`
- `TF_VAR_dsql_cluster_endpoint`
- `TF_VAR_dsql_iam_role_arn`

## Example Usage

### Basic Usage

```yaml
name: Deploy Aurora DSQL

on:
  push:
    branches: [main]

jobs:
  deploy:
    permissions:
      id-token: write
      contents: read
      
    runs-on: ubuntu-latest
    
    steps:
      - name: Checkout repository
        uses: actions/checkout@v4
        
      - name: Configure AWS credentials
        uses: aws-actions/configure-aws-credentials@v4
        with:
          aws-region: us-east-1
          role-to-assume: ${{ secrets.AWS_ROLE_ARN }}
          role-session-name: ${{ github.actor }}
    
      - name: Setup Terraform Backend
        uses: alonch/actions-aws-backend-setup@main
        with: 
          instance: my-app

      - name: Create Aurora DSQL Cluster
        uses: realsensesolutions/actions-aws-postgres-db@main
        id: dsql
        with:
          name: my-aurora-dsql
          action: apply
          deletion_protection_enabled: 'false'
          create_iam_role: 'true'
    
      - name: Use outputs
        run: |
          echo "Cluster endpoint: ${{ steps.dsql.outputs.cluster_endpoint }}"
          echo "IAM Role ARN: ${{ steps.dsql.outputs.iam_role_arn }}"
```

### With Network Action

```yaml
- name: Setup Terraform Backend
  uses: alonch/actions-aws-backend-setup@main
  with: 
    instance: my-app

- name: Network
  id: network
  uses: realsensesolutions/actions-aws-network@main

- name: Create Aurora DSQL Cluster
  uses: realsensesolutions/actions-aws-postgres-db@main
  id: dsql
  with:
    name: my-aurora-dsql
    action: apply
```

## Connecting to Aurora DSQL

Aurora DSQL uses IAM-based authentication. No passwords are required.

### Generate Authentication Token

```bash
aws dsql generate-db-connect-admin-auth-token \
    --hostname <cluster_endpoint> \
    --region <aws_region>
```

### Connect with psql

```bash
TOKEN=$(aws dsql generate-db-connect-admin-auth-token \
    --hostname <cluster_endpoint> \
    --region us-east-1)

PGPASSWORD="$TOKEN" psql \
    -h <cluster_endpoint> \
    -p 5432 \
    -U admin \
    -d postgres \
    "sslmode=require"
```

## Comparison with actions-aws-aurora-dsql

This action is a **simplified version** of [actions-aws-aurora-dsql](https://github.com/realsensesolutions/actions-aws-aurora-dsql):

| Feature | actions-aws-aurora-dsql | This Action |
|---------|------------------------|-------------|
| VPC Endpoints | ✅ Creates | ❌ None (uses public endpoint) |
| Security Groups | ✅ Creates | ❌ None |
| KMS Key | ✅ Optional | ❌ Uses AWS managed |
| Connectivity | VPC Endpoint DNS | Public endpoint |
| Backend Key | ❌ Uses `inputs.name` | ✅ Uses `TF_VAR_instance` |
| Naming | ❌ `-dsql-dsql` duplicates | ✅ Clean naming |

### When to Use This Action

- Development and testing environments
- Scenarios where VPC endpoints are not needed
- Cost optimization (VPC endpoints have hourly charges)
- Simpler setup without network configuration

### When to Use actions-aws-aurora-dsql

- Production environments requiring private connectivity
- Lambda functions in VPC that need to connect to DSQL
- Compliance requirements for private endpoints

## Important Notes

- Aurora DSQL enforces SSL connections (`sslmode=require`)
- Authentication tokens are short-lived and must be regenerated regularly
- The service is currently available in select AWS regions
- Pricing is based on read/write operations and storage usage

## Resources Created

This action creates the following AWS resources:

1. **aws_dsql_cluster** - The Aurora DSQL cluster
2. **aws_iam_role** - IAM role for database access (optional)
3. **aws_iam_role_policy** - IAM policy for DSQL permissions (optional)

## Troubleshooting

### Authentication Token Generation Failed

Ensure your IAM user/role has the `dsql:DbConnectAdmin` permission:

```json
{
  "Effect": "Allow",
  "Action": [
    "dsql:DbConnect",
    "dsql:DbConnectAdmin"
  ],
  "Resource": "<cluster_arn>"
}
```

### Region Not Supported

Aurora DSQL is only available in select regions. Check AWS documentation for current availability.

### State Lock Timeout

If you encounter state lock issues, increase the `lock-timeout` input:

```yaml
- uses: realsensesolutions/actions-aws-postgres-db@main
  with:
    name: my-dsql
    lock-timeout: '10m'
```

## License

This project is licensed under the Apache License 2.0.
