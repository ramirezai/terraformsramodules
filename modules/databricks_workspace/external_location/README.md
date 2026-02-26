# External Location Module

Creates Databricks external locations on AWS with support for:

- **Existing bucket**: Use an S3 bucket that already contains data (read-only or read-write)
- **New bucket**: Create a new S3 bucket for catalog storage

Optionally creates a Unity Catalog catalog from the external location.

## Usage

### Existing Bucket (Read-Only)

For accessing existing data without modification:

```hcl
module "external_location_existing_readonly" {
  source = "../modules/databricks_workspace/external_location"
  providers = {
    databricks = databricks.created_workspace
  }

  create_bucket            = false
  bucket_name              = "my-existing-data-bucket"
  external_location_name   = "existing_data_location"
  read_only                = true

  aws_account_id   = var.aws_account_id
  resource_prefix  = local.resource_prefix
  workspace_id     = local.workspace_id
  unity_catalog_iam_arn = local.unity_catalog_iam_arn
}
```

### Existing Bucket (Read-Write) with KMS

For creating tables in an existing bucket (e.g., for a catalog):

```hcl
module "external_location_existing_rw" {
  source = "../modules/databricks_workspace/external_location"
  providers = {
    databricks = databricks.created_workspace
  }

  create_bucket                  = false
  bucket_name                    = "my-existing-bucket"
  external_location_name         = "existing_rw_location"
  read_only                      = false
  existing_bucket_kms_key_arn    = "arn:aws:kms:us-east-1:123456789012:key/xxx"

  create_catalog                 = true
  catalog_name                   = "my_catalog"
  catalog_admin                  = var.admin_user

  aws_account_id   = var.aws_account_id
  resource_prefix  = local.resource_prefix
  workspace_id     = local.workspace_id
  unity_catalog_iam_arn = local.unity_catalog_iam_arn
}
```

### New Bucket with Catalog

Creates a new S3 bucket and optionally a catalog:

```hcl
module "external_location_new_bucket" {
  source = "../modules/databricks_workspace/external_location"
  providers = {
    databricks = databricks.created_workspace
  }

  create_bucket          = true
  bucket_name            = "${local.resource_prefix}-new-catalog-${local.workspace_id}"
  external_location_name = "new_catalog_location"

  create_catalog         = true
  catalog_name           = "new_catalog"
  catalog_admin          = var.admin_user

  aws_account_id   = var.aws_account_id
  resource_prefix  = local.resource_prefix
  workspace_id     = local.workspace_id
  cmk_admin_arn    = var.cmk_admin_arn
  unity_catalog_iam_arn = local.unity_catalog_iam_arn
}
```

### Subpath Within Bucket

Use a specific prefix within the bucket:

```hcl
module "external_location_subpath" {
  source = "../modules/databricks_workspace/external_location"
  providers = {
    databricks = databricks.created_workspace
  }

  create_bucket          = false
  bucket_name            = "my-bucket"
  storage_path           = "data/lake/analytics"
  external_location_name = "analytics_location"
  read_only              = false

  aws_account_id   = var.aws_account_id
  resource_prefix  = local.resource_prefix
  workspace_id     = local.workspace_id
  unity_catalog_iam_arn = local.unity_catalog_iam_arn
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| create_bucket | When true, creates a new S3 bucket. When false, uses existing bucket. | bool | false | no |
| bucket_name | S3 bucket name (new or existing). | string | n/a | yes |
| storage_path | Subpath within bucket (e.g., "data/lake"). Empty for root. | string | "" | no |
| read_only | For existing bucket: true = read-only, false = read-write. | bool | true | no |
| existing_bucket_kms_key_arn | KMS key ARN if existing bucket uses SSE-KMS. | string | "" | no |
| external_location_name | Name for the Databricks external location. | string | n/a | yes |
| create_catalog | Create a Unity Catalog from this location. | bool | false | no |
| catalog_name | Catalog name (when create_catalog=true). | string | "" | no |
| catalog_admin | Principal to grant catalog admin (when create_catalog=true). | string | "" | no |

## Outputs

| Name | Description |
|------|-------------|
| external_location_name | Name of the external location |
| external_location_url | S3 URL of the location |
| storage_credential_name | Storage credential name |
| bucket_name | S3 bucket name |
| iam_role_arn | IAM role ARN |
| catalog_name | Catalog name (if created) |
