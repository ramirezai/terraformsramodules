variable "admin_user" {
  description = "Email of the admin user for the workspace and workspace catalog."
  type        = string
}

variable "aws_account_id" {
  description = "ID of the AWS account."
  type        = string
  sensitive   = true
}

variable "aws_partition" {
  description = "AWS partition to use for ARNs and policies"
  type        = string
  default     = null

  validation {
    condition     = var.aws_partition == null || can(contains(["aws", "aws-us-gov"], var.aws_partition))
    error_message = "Invalid AWS partition. Allowed values are: aws, aws-us-gov."
  }
}

variable "cmk_admin_arn" {
  description = "Amazon Resource Name (ARN) of the CMK admin."
  type        = string
  default     = null
}

variable "compliance_standards" {
  description = "List of compliance standards."
  type        = list(string)
  nullable    = true
}

variable "databricks_gov_shard" {
  description = "Databricks GovCloud shard type (civilian or dod). Only applicable for us-gov-west-1 region."
  type        = string
  default     = null

  validation {
    condition     = var.databricks_gov_shard == null || can(contains(["civilian", "dod"], var.databricks_gov_shard))
    error_message = "Invalid databricks_gov_shard. Allowed values are: null, civilian, dod."
  }
}

variable "enable_compliance_security_profile" {
  description = "Flag to enable the compliance security profile."
  type        = bool
  sensitive   = true
  default     = false
}

variable "enable_security_analysis_tool" {
  description = "Flag to enable the security analysis tool."
  type        = bool
  sensitive   = true
  default     = false
}

variable "environment" {
  description = "Environment name (e.g., dev, prod). Used for remote state lookup."
  type        = string
}

variable "platform_state_bucket" {
  description = "S3 bucket name where platform layer state is stored."
  type        = string
}

variable "region" {
  description = "AWS region code. (e.g. us-east-1)"
  type        = string
  validation {
    condition     = contains(["ap-northeast-1", "ap-northeast-2", "ap-south-1", "ap-southeast-1", "ap-southeast-2", "ap-southeast-3", "ca-central-1", "eu-central-1", "eu-west-1", "eu-west-2", "eu-west-3", "sa-east-1", "us-east-1", "us-east-2", "us-west-1", "us-west-2", "us-gov-west-1"], var.region)
    error_message = "Valid values for var: region are (ap-northeast-1, ap-northeast-2, ap-south-1, ap-southeast-1, ap-southeast-2, ap-southeast-3, ca-central-1, eu-central-1, eu-west-1, eu-west-2, eu-west-3, sa-east-1, us-east-1, us-east-2, us-west-1, us-west-2, us-gov-west-1)."
  }
}

# Locals from platform state
locals {
  resource_prefix       = data.terraform_remote_state.platform.outputs.resource_prefix
  workspace_id         = data.terraform_remote_state.platform.outputs.workspace_id
  region_name          = data.terraform_remote_state.platform.outputs.region_name
  root_bucket_name     = data.terraform_remote_state.platform.outputs.root_bucket_name
  databricks_account_id = data.terraform_remote_state.platform.outputs.databricks_account_id

  computed_aws_partition = var.aws_partition != null ? var.aws_partition : (
    var.region == "us-gov-west-1" ? "aws-us-gov" : "aws"
  )

  assume_role_partition = var.region == "us-gov-west-1" ? (
    var.databricks_gov_shard == "dod" ? "aws-us-gov-dod" : "aws-us-gov"
  ) : "aws"

  unity_catalog_iam_arn = var.region == "us-gov-west-1" ? (
    var.databricks_gov_shard == "dod" ? "arn:aws-us-gov:iam::170661010020:role/unity-catalog-prod-UCMasterRole-1DI6DL6ZP26AS" : "arn:aws-us-gov:iam::044793339203:role/unity-catalog-prod-UCMasterRole-1QRFA8SGY15OJ"
  ) : "arn:aws:iam::414351767826:role/unity-catalog-prod-UCMasterRole-14S5ZJVKOTYTL"
}
