# =============================================================================
# Databricks Workspace Modules
# =============================================================================

# Creates a Workspace Isolated Catalog
module "unity_catalog_catalog_creation" {
  source = "../modules/databricks_workspace/unity_catalog_catalog_creation"
  providers = {
    databricks = databricks.created_workspace
  }

  aws_account_id               = var.aws_account_id
  aws_iam_partition            = local.computed_aws_partition
  aws_assume_partition         = local.assume_role_partition
  unity_catalog_iam_arn        = local.unity_catalog_iam_arn
  resource_prefix              = local.resource_prefix
  uc_catalog_name              = "${local.resource_prefix}-catalog-${local.workspace_id}"
  cmk_admin_arn                = var.cmk_admin_arn == null ? "arn:${local.computed_aws_partition}:iam::${var.aws_account_id}:root" : var.cmk_admin_arn
  workspace_id                 = local.workspace_id
  user_workspace_catalog_admin = var.admin_user
}

# Restrictive Root Bucket Policy
module "restrictive_root_bucket" {
  source = "../modules/databricks_workspace/restrictive_root_bucket"
  providers = {
    aws = aws
  }

  databricks_account_id = local.databricks_account_id
  aws_partition         = local.computed_aws_partition
  databricks_gov_shard  = var.databricks_gov_shard
  workspace_id          = local.workspace_id
  region_name           = local.region_name
  root_s3_bucket        = local.root_bucket_name
}

# Disable legacy settings like Hive Metastore, Disables Databricks Runtime prior to 13.3 LTS, DBFS, DBFS Mounts, etc.
module "disable_legacy_settings" {
  source = "../modules/databricks_workspace/disable_legacy_settings"
  providers = {
    databricks = databricks.created_workspace
  }
}

# Enable Compliance Security Profile (CSP) on the Databricks Workspace.
module "compliance_security_profile" {
  count  = var.enable_compliance_security_profile ? 1 : 0
  source = "../modules/databricks_workspace/compliance_security_profile"

  providers = {
    databricks = databricks.created_workspace
  }

  compliance_standards = var.compliance_standards
}

# Create Cluster
module "cluster_configuration" {
  source = "../modules/databricks_workspace/classic_cluster"
  providers = {
    databricks = databricks.created_workspace
  }

  enable_compliance_security_profile = var.enable_compliance_security_profile
  resource_prefix                    = local.resource_prefix
  region                             = var.region
}

# Dynamic External Locations
module "external_locations" {
  for_each = var.external_locations
  source   = "../modules/databricks_workspace/external_location"
  providers = {
    databricks = databricks.created_workspace
  }

  create_bucket               = each.value.create_bucket
  bucket_name                 = each.value.bucket_name
  storage_path                = each.value.storage_path
  read_only                   = each.value.read_only
  existing_bucket_kms_key_arn = each.value.existing_bucket_kms_key_arn
  external_location_name      = each.key
  create_catalog              = each.value.create_catalog
  catalog_name                = each.value.catalog_name
  catalog_admin               = each.value.create_catalog ? var.admin_user : ""

  aws_account_id        = var.aws_account_id
  aws_iam_partition     = local.computed_aws_partition
  aws_assume_partition  = local.assume_role_partition
  resource_prefix       = local.resource_prefix
  workspace_id          = local.workspace_id
  cmk_admin_arn         = each.value.create_bucket ? coalesce(var.cmk_admin_arn, "arn:${local.computed_aws_partition}:iam::${var.aws_account_id}:root") : null
  unity_catalog_iam_arn = local.unity_catalog_iam_arn
}

# =============================================================================
# Security Analysis Tool - PyPI must be enabled in network policy resource to function.
# =============================================================================

module "security_analysis_tool" {
  count  = var.enable_security_analysis_tool && var.region != "us-gov-west-1" ? 1 : 0
  source = "../modules/security_analysis_tool"

  providers = {
    databricks = databricks.created_workspace
  }

  databricks_account_id = local.databricks_account_id
  client_id             = null
  client_secret         = null

  use_sp_auth = true

  analysis_schema_name = replace("${local.resource_prefix}-catalog-${local.workspace_id}.SAT", "-", "_")
  workspace_id         = local.workspace_id

  proxies           = {}
  run_on_serverless = true

  depends_on = [module.unity_catalog_catalog_creation]
}
