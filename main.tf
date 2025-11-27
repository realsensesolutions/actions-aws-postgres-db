# =============================================================================
# Aurora DSQL Cluster
# =============================================================================
# Simple, reliable DSQL cluster creation.
# - NO VPC endpoints (uses public endpoint)
# - NO security groups (DSQL handles internally)
# - NO KMS keys (uses AWS managed encryption)
# - Clean naming (no duplicate suffixes like -dsql-dsql)
# =============================================================================

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

# =============================================================================
# DSQL Cluster
# =============================================================================
resource "aws_dsql_cluster" "main" {
  deletion_protection_enabled = var.deletion_protection_enabled

  tags = {
    Name      = var.cluster_name
    ManagedBy = "terraform"
  }
}

# =============================================================================
# IAM Role for DSQL Access (optional)
# Allows Lambda and other services to connect to the cluster
# =============================================================================
resource "aws_iam_role" "admin" {
  count = var.create_iam_role ? 1 : 0

  # Simple naming - user controls the prefix
  name = "${var.cluster_name}-admin"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = "sts:AssumeRole"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
      }
    ]
  })

  tags = {
    Name      = "${var.cluster_name}-admin"
    ManagedBy = "terraform"
  }
}

resource "aws_iam_role_policy" "admin" {
  count = var.create_iam_role ? 1 : 0

  name = "dsql-access"
  role = aws_iam_role.admin[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "dsql:DbConnect",
          "dsql:DbConnectAdmin"
        ]
        Resource = aws_dsql_cluster.main.arn
      }
    ]
  })
}
