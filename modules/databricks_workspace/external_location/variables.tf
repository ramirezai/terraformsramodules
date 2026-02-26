variable "aws_account_id" {
  type        = string
  description = "ID of the AWS account."
}

variable "aws_iam_partition" {
  type        = string
  description = "AWS partition to use for IAM ARNs and policies."
  default     = "aws"
}

variable "aws_assume_partition" {
  type        = string
  description = "AWS partition to use for assume role policies."
  default     = "aws"
}

variable "unity_catalog_iam_arn" {
  type        = string
  description = "Unity Catalog IAM ARN for the master role."
  default     = "arn:aws:iam::414351767826:role/unity-catalog-prod-UCMasterRole-14S5ZJVKOTYTL"
}

variable "cmk_admin_arn" {
  type        = string
  description = "Amazon Resource Name (ARN) of the CMK admin. Required when create_bucket is true. Can be set to account root (e.g., arn:aws:iam::ACCOUNT_ID:root) when using existing bucket."
  default     = null
}

variable "resource_prefix" {
  type        = string
  description = "Prefix for resource names."
}

variable "workspace_id" {
  type        = string
  description = "Workspace ID of the deployed workspace."
}

# -----------------------------------------------------------------------------
# Bucket configuration
# -----------------------------------------------------------------------------

variable "create_bucket" {
  type        = bool
  description = "When true, creates a new S3 bucket. When false, uses an existing bucket specified by bucket_name."
  default     = false
}

variable "bucket_name" {
  type        = string
  description = "S3 bucket name. For create_bucket=true, this is the name for the new bucket. For create_bucket=false, this is the existing bucket name."
}

variable "storage_path" {
  type        = string
  description = "Optional subpath within the bucket (e.g., 'data/lake'). Use empty string for bucket root."
  default     = ""
}

# -----------------------------------------------------------------------------
# Existing bucket options (when create_bucket = false)
# -----------------------------------------------------------------------------

variable "read_only" {
  type        = bool
  description = "When using an existing bucket, set to true for read-only access (e.g., existing data). Set to false for read-write (e.g., creating tables)."
  default     = true
}

variable "existing_bucket_kms_key_arn" {
  type        = string
  description = "ARN of the KMS key used to encrypt the existing bucket. Required if the existing bucket uses SSE-KMS encryption. Leave empty for SSE-S3 or unencrypted."
  default     = ""
}

# -----------------------------------------------------------------------------
# External location configuration
# -----------------------------------------------------------------------------

variable "external_location_name" {
  type        = string
  description = "Name for the Databricks external location."
}

variable "comment" {
  type        = string
  description = "Comment for the external location."
  default     = ""
}

# -----------------------------------------------------------------------------
# Catalog creation (optional)
# -----------------------------------------------------------------------------

variable "create_catalog" {
  type        = bool
  description = "When true, creates a Unity Catalog catalog using this external location as storage_root. Requires read_only=false when using existing bucket."
  default     = false

  validation {
    condition     = !var.create_catalog || var.create_bucket || !var.read_only
    error_message = "create_catalog requires read_only=false when using an existing bucket (create_bucket=false)."
  }
}

variable "catalog_name" {
  type        = string
  description = "Name for the catalog. Only used when create_catalog is true. Use underscores (e.g., my_catalog) as hyphens are replaced."
  default     = ""
}

variable "catalog_admin" {
  type        = string
  description = "Principal (user or group) to grant ALL_PRIVILEGES on the catalog. Only used when create_catalog is true."
  default     = ""
}
