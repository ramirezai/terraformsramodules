output "external_location_name" {
  description = "Name of the Databricks external location."
  value       = databricks_external_location.ext_location.name
}

output "external_location_url" {
  description = "S3 URL of the external location."
  value       = databricks_external_location.ext_location.url
}

output "storage_credential_name" {
  description = "Name of the storage credential used by the external location."
  value       = databricks_storage_credential.ext_location.name
}

output "bucket_name" {
  description = "S3 bucket name (existing or created)."
  value       = var.bucket_name
}

output "iam_role_arn" {
  description = "ARN of the IAM role used for the storage credential."
  value       = aws_iam_role.ext_location.arn
}

output "catalog_name" {
  description = "Name of the catalog, if create_catalog was true."
  value       = var.create_catalog ? databricks_catalog.ext_location[0].name : null
}
