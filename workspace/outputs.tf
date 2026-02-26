output "workspace_host" {
  description = "Workspace URL for the Databricks workspace."
  value       = data.terraform_remote_state.platform.outputs.workspace_host
}

output "catalog_name" {
  description = "Name of the catalog created for the workspace"
  value       = module.unity_catalog_catalog_creation.catalog_name
}
