# Environment Configurations

This directory contains environment-specific variable files and backend configuration for the layered Terraform deployment.

## Structure

### Variable files (tfvars)

- `dev/platform.tfvars` - Platform layer variables for development
- `dev/workspace.tfvars` - Workspace layer variables for development
- `prod/platform.tfvars` - Platform layer variables for production
- `prod/workspace.tfvars` - Workspace layer variables for production

### Backend config files (hcl)

- `dev/platform-backend.hcl` - Platform S3 backend config for dev
- `dev/workspace-backend.hcl` - Workspace S3 backend config for dev
- `prod/platform-backend.hcl` - Platform S3 backend config for prod
- `prod/workspace-backend.hcl` - Workspace S3 backend config for prod

## Usage

1. Fill in `bucket`, `key`, and `region` in the appropriate `*-backend.hcl` files for your environment.
2. Fill in the tfvars files with your values.
3. Ensure `platform_state_bucket` in workspace.tfvars matches the `bucket` value in the platform backend config (e.g., `dev/platform-backend.hcl`).
4. Ensure `environment` in workspace.tfvars matches the state path (e.g., "dev" for `platform/dev/terraform.tfstate`).

## Troubleshooting

**"Backend configuration changed" / 403 Forbidden on init:**
- Use `-reconfigure` with init to apply the new backend config without migrating: `terraform init -backend-config=../environments/dev/workspace-backend.hcl -reconfigure`
- Use `-migrate-state` only when copying state from an existing backend to the new one.
