# =============================================================================
# Databricks Account Modules
# =============================================================================

# Create Unity Catalog Metastore
module "unity_catalog_metastore_creation" {
  source = "../modules/databricks_account/unity_catalog_metastore_creation"
  providers = {
    databricks = databricks.mws
  }

  region           = var.region
  metastore_exists = var.metastore_exists
}

# Create Network Connectivity Connection Object
module "network_connectivity_configuration" {
  source = "../modules/databricks_account/network_connectivity_configuration"
  providers = {
    databricks = databricks.mws
  }

  region          = var.region
  resource_prefix = var.resource_prefix
}

# Create a Network Policy
module "network_policy" {
  source = "../modules/databricks_account/network_policy"
  providers = {
    databricks = databricks.mws
  }

  databricks_account_id = var.databricks_account_id
  resource_prefix       = var.resource_prefix
}

# Create Databricks Workspace
module "databricks_mws_workspace" {
  source = "../modules/databricks_account/workspace"

  providers = {
    databricks = databricks.mws
  }

  # Basic Configuration
  databricks_account_id = var.databricks_account_id
  resource_prefix       = var.resource_prefix
  region                = var.region
  deployment_name       = var.deployment_name

  # Network Configuration
  vpc_id             = var.custom_vpc_id != null ? var.custom_vpc_id : module.vpc[0].vpc_id
  subnet_ids         = var.custom_private_subnet_ids != null ? var.custom_private_subnet_ids : module.vpc[0].private_subnets
  security_group_ids = var.custom_sg_id != null ? [var.custom_sg_id] : [aws_security_group.sg[0].id]
  backend_rest       = var.custom_workspace_vpce_id != null ? var.custom_workspace_vpce_id : aws_vpc_endpoint.backend_rest[0].id
  backend_relay      = var.custom_relay_vpce_id != null ? var.custom_relay_vpce_id : aws_vpc_endpoint.backend_relay[0].id

  # Cross-Account Role
  cross_account_role_arn = aws_iam_role.cross_account_role.arn

  # Root Storage Bucket
  bucket_name = aws_s3_bucket.root_storage_bucket.id

  # KMS Keys
  managed_services_key        = aws_kms_key.managed_services.arn
  workspace_storage_key       = aws_kms_key.workspace_storage.arn
  managed_services_key_alias  = aws_kms_alias.managed_services_key_alias.name
  workspace_storage_key_alias = aws_kms_alias.workspace_storage_key_alias.name

  # Network Connectivity Configuration and Network Policy
  network_connectivity_configuration_id = module.network_connectivity_configuration.ncc_id
  network_policy_id                     = module.network_policy.network_policy_id

  depends_on = [module.unity_catalog_metastore_creation, module.network_connectivity_configuration, module.network_policy]
}

# Unity Catalog Assignment
module "unity_catalog_metastore_assignment" {
  source = "../modules/databricks_account/unity_catalog_metastore_assignment"
  providers = {
    databricks = databricks.mws
  }

  metastore_id = module.unity_catalog_metastore_creation.metastore_id
  workspace_id = module.databricks_mws_workspace.workspace_id

  depends_on = [module.unity_catalog_metastore_creation, module.databricks_mws_workspace]
}

# User Workspace Assignment (Admin)
module "user_assignment" {
  source = "../modules/databricks_account/user_assignment"
  providers = {
    databricks = databricks.mws
  }

  workspace_id     = module.databricks_mws_workspace.workspace_id
  workspace_access = var.admin_user

  depends_on = [module.unity_catalog_metastore_assignment, module.databricks_mws_workspace]
}

# Audit Log Delivery
module "log_delivery" {
  count  = var.audit_log_delivery_exists ? 0 : 1
  source = "../modules/databricks_account/audit_log_delivery"
  providers = {
    databricks = databricks.mws
  }

  databricks_account_id = var.databricks_account_id
  resource_prefix       = var.resource_prefix
  aws_assume_partition  = local.assume_role_partition
}
