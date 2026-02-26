output "workspace_host" {
  description = "Workspace URL for the Databricks workspace provider."
  value       = module.databricks_mws_workspace.workspace_url
}

output "workspace_id" {
  description = "Workspace ID."
  value       = module.databricks_mws_workspace.workspace_id
}

output "root_bucket_name" {
  description = "Name of the workspace root storage bucket."
  value       = aws_s3_bucket.root_storage_bucket.id
}

output "resource_prefix" {
  description = "Prefix used for resource names."
  value       = var.resource_prefix
}

output "region" {
  description = "AWS region."
  value       = var.region
}

output "databricks_account_id" {
  description = "Databricks account ID."
  value       = var.databricks_account_id
  sensitive   = true
}

output "region_name" {
  description = "Region name for the current region (used by workspace layer)."
  value       = var.databricks_gov_shard == "dod" ? var.region_name_config[var.region].secondary_name : var.region_name_config[var.region].primary_name
}
