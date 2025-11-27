# =============================================================================
# Variables
# =============================================================================

variable "cluster_name" {
  description = "Name for the Aurora DSQL cluster"
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9-]+$", var.cluster_name)) && length(var.cluster_name) <= 63
    error_message = "Cluster name: lowercase letters, numbers, hyphens only, max 63 chars."
  }
}

variable "deletion_protection_enabled" {
  description = "Enable deletion protection"
  type        = bool
  default     = true
}

variable "create_iam_role" {
  description = "Create IAM role for DSQL access"
  type        = bool
  default     = true
}
