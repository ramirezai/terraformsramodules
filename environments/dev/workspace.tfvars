# =============================================================================
# Workspace Layer - Development Environment
# =============================================================================

# -----------------------------------------------------------------------------
# Platform State Configuration
# -----------------------------------------------------------------------------
platform_state_bucket = "joelststerraformstates3"
environment          = "dev"

# -----------------------------------------------------------------------------
# AWS Variables
# -----------------------------------------------------------------------------
aws_account_id = "332745928618"
region         = "us-east-1"

# -----------------------------------------------------------------------------
# Databricks Variables
# -----------------------------------------------------------------------------
admin_user = "joel.ramirez@databricks.com"

# -----------------------------------------------------------------------------
# Feature Flags
# -----------------------------------------------------------------------------
enable_security_analysis_tool = false
enable_compliance_security_profile = false
compliance_standards = ["Standard_A", "Standard_B"]

# -----------------------------------------------------------------------------
# Optional Configuration
# -----------------------------------------------------------------------------
databricks_gov_shard = null
cmk_admin_arn       = null

# -----------------------------------------------------------------------------
# External Locations (optional)
# -----------------------------------------------------------------------------
external_locations = {
  "existing_data" = {
    create_bucket  = false
    bucket_name    = "joelstsdemobucketingestion"
    read_only      = true
    create_catalog = false
  }
  "new_catalog" = {
    create_bucket  = true
    bucket_name    = "joelsts-catalog-12345"
    create_catalog = true
    catalog_name   = "ext_catalog"
  }
}
