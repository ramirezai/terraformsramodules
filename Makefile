# Terraform SRA - Run from aws/ directory
# Usage: make workspace-apply ENV=dev

ENV ?= dev

.PHONY: workspace-init workspace-plan workspace-apply workspace-destroy platform-init platform-plan platform-apply platform-destroy

workspace-init:
	cd workspace && terraform init -backend-config=../environments/$(ENV)/workspace-backend.hcl -reconfigure

workspace-plan:
	cd workspace && terraform plan -var-file=../environments/$(ENV)/workspace.tfvars

workspace-apply:
	cd workspace && terraform apply -var-file=../environments/$(ENV)/workspace.tfvars

workspace-destroy:
	cd workspace && terraform destroy -var-file=../environments/$(ENV)/workspace.tfvars

platform-init:
	cd platform && terraform init -backend-config=../environments/$(ENV)/platform-backend.hcl -reconfigure

platform-plan:
	cd platform && terraform plan -var-file=../environments/$(ENV)/platform.tfvars

platform-apply:
	cd platform && terraform apply -var-file=../environments/$(ENV)/platform.tfvars

platform-destroy:
	cd platform && terraform destroy -var-file=../environments/$(ENV)/platform.tfvars
