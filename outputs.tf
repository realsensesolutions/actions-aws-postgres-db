# =============================================================================
# Outputs
# =============================================================================

output "cluster_arn" {
  description = "ARN of the Aurora DSQL cluster"
  value       = aws_dsql_cluster.main.arn
}

output "cluster_id" {
  description = "ID of the Aurora DSQL cluster"
  value       = regex("[^/]+$", aws_dsql_cluster.main.arn)
}

output "cluster_endpoint" {
  description = "Public endpoint of the Aurora DSQL cluster"
  value       = "${regex("[^/]+$", aws_dsql_cluster.main.arn)}.dsql.${data.aws_region.current.name}.on.aws"
}

output "vpc_endpoint_service_name" {
  description = "VPC endpoint service name (for creating VPC endpoint later)"
  value       = aws_dsql_cluster.main.vpc_endpoint_service_name
}

output "iam_role_arn" {
  description = "ARN of the IAM role for DSQL access"
  value       = var.create_iam_role ? aws_iam_role.admin[0].arn : null
}

output "region" {
  description = "AWS region"
  value       = data.aws_region.current.name
}
