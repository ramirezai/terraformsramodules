# =============================================================================
# External Location Module - Databricks AWS
# Supports: existing bucket (read-only or read-write) OR new bucket creation
# Optional: Unity Catalog creation from the external location
# =============================================================================

resource "null_resource" "previous" {}

# Wait to prevent race condition between IAM role and external location validation
resource "time_sleep" "wait_60_seconds" {
  depends_on      = [null_resource.previous]
  create_duration = "60s"
}

locals {
  iam_role_name   = "${var.resource_prefix}-ext-loc-${replace(var.external_location_name, "_", "-")}-${var.workspace_id}"
  storage_url     = var.storage_path != "" ? "s3://${var.bucket_name}/${trim(var.storage_path, "/")}/" : "s3://${var.bucket_name}/"
  catalog_name   = var.create_catalog ? (var.catalog_name != "" ? replace(var.catalog_name, "-", "_") : replace(var.external_location_name, "-", "_")) : null
  location_comment = var.comment != "" ? var.comment : "External location for ${var.external_location_name}"
}

# =============================================================================
# New Bucket Path: KMS, S3 bucket, Unity Catalog policy
# =============================================================================

resource "aws_kms_key" "storage" {
  count = var.create_bucket ? 1 : 0

  description = "KMS key for Databricks external location ${var.external_location_name}"
  policy = jsonencode({
    Version = "2012-10-17"
    Id      = "key-policy-ext-loc-${var.external_location_name}"
    Statement = [
      {
        Sid    = "Enable IAM User Permissions"
        Effect = "Allow"
        Principal = {
          AWS = [coalesce(var.cmk_admin_arn, "arn:${var.aws_iam_partition}:iam::${var.aws_account_id}:root")]
        }
        Action   = "kms:*"
        Resource = "*"
      },
      {
        Sid    = "Allow IAM Role to use the key"
        Effect = "Allow"
        Principal = {
          AWS = "arn:${var.aws_iam_partition}:iam::${var.aws_account_id}:role/${local.iam_role_name}"
        }
        Action = [
          "kms:Decrypt",
          "kms:Encrypt",
          "kms:GenerateDataKey*"
        ]
        Resource = "*"
      }
    ]
  })
  tags = {
    Name    = "${var.resource_prefix}-ext-loc-${var.external_location_name}-key"
    Project = var.resource_prefix
  }
}

resource "aws_kms_alias" "storage_key_alias" {
  count         = var.create_bucket ? 1 : 0
  name          = "alias/${var.resource_prefix}-ext-loc-${var.external_location_name}-key"
  target_key_id = aws_kms_key.storage[0].id
}

# S3 Bucket (only when create_bucket = true)
resource "aws_s3_bucket" "storage" {
  count = var.create_bucket ? 1 : 0

  bucket        = var.bucket_name
  force_destroy = true
  tags = {
    Name    = var.bucket_name
    Project = var.resource_prefix
  }
}

resource "aws_s3_bucket_versioning" "storage" {
  count = var.create_bucket ? 1 : 0

  bucket = aws_s3_bucket.storage[0].id
  versioning_configuration {
    status = "Disabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "storage" {
  count = var.create_bucket ? 1 : 0

  bucket = aws_s3_bucket.storage[0].bucket
  rule {
    bucket_key_enabled = true
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = aws_kms_key.storage[0].arn
    }
  }
  depends_on = [aws_kms_alias.storage_key_alias]
}

resource "aws_s3_bucket_public_access_block" "storage" {
  count = var.create_bucket ? 1 : 0

  bucket                  = aws_s3_bucket.storage[0].id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# =============================================================================
# Storage Credential (created before IAM role - required for external_id)
# =============================================================================

resource "databricks_storage_credential" "ext_location" {
  name = "${var.external_location_name}-storage-credential"
  aws_iam_role {
    role_arn = "arn:${var.aws_iam_partition}:iam::${var.aws_account_id}:role/${local.iam_role_name}"
  }
  isolation_mode = "ISOLATION_MODE_ISOLATED"
}

# =============================================================================
# IAM Role - Trust Policy (same for both paths)
# Unity Catalog requires the role to be self-assuming - the role must trust itself
# =============================================================================

data "databricks_aws_unity_catalog_assume_role_policy" "ext_location" {
  aws_account_id        = var.aws_account_id
  aws_partition         = var.aws_assume_partition
  role_name             = local.iam_role_name
  unity_catalog_iam_arn = var.unity_catalog_iam_arn
  external_id           = databricks_storage_credential.ext_location.aws_iam_role[0].external_id
}

# Add self-assume to trust policy: role must trust itself per Unity Catalog requirements
locals {
  role_arn          = "arn:${var.aws_iam_partition}:iam::${var.aws_account_id}:role/${local.iam_role_name}"
  base_trust_policy = jsondecode(data.databricks_aws_unity_catalog_assume_role_policy.ext_location.json)
  # Handle both string and list for Principal.AWS
  base_principals  = local.base_trust_policy.Statement[0].Principal.AWS
  principals_list  = try(tolist(local.base_principals), [tostring(local.base_principals)])
  trust_principals = distinct(concat(local.principals_list, [local.role_arn]))
  assume_role_policy_with_self = jsonencode({
    Version = local.base_trust_policy.Version
    Statement = [
      merge(local.base_trust_policy.Statement[0], {
        Principal = {
          AWS = local.trust_principals
        }
      })
    ]
  })
}

resource "aws_iam_role" "ext_location" {
  name               = local.iam_role_name
  assume_role_policy = local.assume_role_policy_with_self
  tags = {
    Name    = local.iam_role_name
    Project = var.resource_prefix
  }
}

# Wait for AWS IAM trust policy propagation before Databricks validates the role
resource "time_sleep" "wait_iam_propagation" {
  depends_on      = [aws_iam_role.ext_location]
  create_duration = "30s"
}

# =============================================================================
# IAM Policy - New Bucket: Use Databricks Unity Catalog policy
# =============================================================================

data "databricks_aws_unity_catalog_policy" "new_bucket" {
  count = var.create_bucket ? 1 : 0

  aws_account_id = var.aws_account_id
  aws_partition  = var.aws_assume_partition
  bucket_name    = var.bucket_name
  role_name      = local.iam_role_name
  kms_name       = aws_kms_key.storage[0].arn
}

resource "aws_iam_policy" "new_bucket" {
  count = var.create_bucket ? 1 : 0

  name   = "${var.resource_prefix}-ext-loc-policy-${var.external_location_name}"
  policy = data.databricks_aws_unity_catalog_policy.new_bucket[0].json
}

resource "aws_iam_policy_attachment" "new_bucket" {
  count = var.create_bucket ? 1 : 0

  name       = "ext_location_policy_attach"
  roles      = [aws_iam_role.ext_location.name]
  policy_arn = aws_iam_policy.new_bucket[0].arn
}

# =============================================================================
# IAM Policy - Existing Bucket: Custom policy (read-only or read-write)
# =============================================================================

locals {
  # S3 actions: read-only vs read-write
  s3_read_actions = [
    "s3:GetObject",
    "s3:ListBucket",
    "s3:GetBucketLocation",
    "s3:GetLifecycleConfiguration"
  ]
  s3_write_actions = [
    "s3:PutObject",
    "s3:DeleteObject",
    "s3:PutObjectAcl",
    "s3:AbortMultipartUpload"
  ]
  s3_actions = var.read_only ? local.s3_read_actions : concat(local.s3_read_actions, local.s3_write_actions)

  # KMS actions when bucket uses KMS encryption
  kms_actions = ["kms:Decrypt", "kms:Encrypt", "kms:GenerateDataKey*"]
  has_kms     = var.existing_bucket_kms_key_arn != ""

  existing_bucket_policy = jsonencode({
    Version = "2012-10-17"
    Statement = concat(
      [
        {
          Effect   = "Allow"
          Action   = local.s3_actions
          Resource = [
            "arn:${var.aws_iam_partition}:s3:::${var.bucket_name}",
            "arn:${var.aws_iam_partition}:s3:::${var.bucket_name}/*"
          ]
        }
      ],
      local.has_kms ? [
        {
          Effect   = "Allow"
          Action   = local.kms_actions
          Resource = [var.existing_bucket_kms_key_arn]
        }
      ] : []
    )
  })
}

resource "aws_iam_role_policy" "existing_bucket" {
  count = var.create_bucket ? 0 : 1

  name   = "${var.resource_prefix}-ext-loc-policy-${var.external_location_name}"
  role   = aws_iam_role.ext_location.id
  policy = local.existing_bucket_policy
}

# =============================================================================
# External Location
# =============================================================================

# IAM policy ready signal - ensures the correct policy exists and IAM has propagated before external location creation
resource "null_resource" "iam_policy_ready" {
  count = 1

  depends_on = [
    aws_iam_role.ext_location,
    aws_iam_policy_attachment.new_bucket,
    aws_iam_role_policy.existing_bucket,
    time_sleep.wait_60_seconds,
    time_sleep.wait_iam_propagation
  ]
}

resource "databricks_external_location" "ext_location" {
  name            = var.external_location_name
  url             = local.storage_url
  credential_name = databricks_storage_credential.ext_location.id
  read_only       = var.create_bucket ? false : var.read_only
  comment         = local.location_comment
  isolation_mode  = "ISOLATION_MODE_ISOLATED"
  depends_on      = [null_resource.iam_policy_ready]
}

# =============================================================================
# Optional: Unity Catalog creation
# =============================================================================

resource "databricks_catalog" "ext_location" {
  count = var.create_catalog ? 1 : 0

  name           = local.catalog_name
  comment        = "Catalog created from external location ${var.external_location_name}"
  isolation_mode = "ISOLATED"
  storage_root   = local.storage_url
  properties = {
    purpose = "Catalog from external location - ${var.external_location_name}"
  }
  depends_on = [databricks_external_location.ext_location]
}

resource "databricks_grant" "catalog_admin" {
  count = var.create_catalog && var.catalog_admin != "" ? 1 : 0

  catalog   = databricks_catalog.ext_location[0].name
  principal = var.catalog_admin
  privileges = ["ALL_PRIVILEGES"]
}
