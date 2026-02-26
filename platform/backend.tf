terraform {
  required_providers {
    databricks = {
      source  = "databricks/databricks"
      version = "~> 1.84"
    }
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.76, <7.0"
    }
  }
  required_version = ">= 1.10"

  backend "s3" {
    # bucket, key, region provided via -backend-config (e.g., -backend-config=../environments/dev/platform-backend.hcl)
    use_lockfile = true
    encrypt      = true
  }
}
