# MedVault Infrastructure — Makefile
# Used for local development and CI/CD pipelines

.PHONY: help tf-init tf-plan tf-validate helm-lint helm-template cf-validate scan-all

help: ## Show this help
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'

# ------- Terraform -------

tf-init: ## Initialize Terraform (usage: make tf-init ENV=dev)
	cd terraform && terraform init -backend-config=environments/$(ENV)/backend.hcl

tf-plan: ## Plan Terraform changes (usage: make tf-plan ENV=dev)
	cd terraform && terraform plan -var-file=environments/$(ENV)/terraform.tfvars -out=tfplan

tf-validate: ## Validate Terraform syntax
	cd terraform && terraform validate

tf-fmt: ## Format Terraform files
	cd terraform && terraform fmt -recursive

# ------- Helm -------

helm-lint: ## Lint all Helm charts
	helm lint helm/patient-api -f helm/patient-api/values.yaml
	helm lint helm/internal-tools -f helm/internal-tools/values.yaml

helm-template: ## Render Helm templates (usage: make helm-template ENV=prod)
	helm template patient-api helm/patient-api -f helm/patient-api/values.yaml -f helm/patient-api/values-$(ENV).yaml
	helm template internal-tools helm/internal-tools -f helm/internal-tools/values.yaml

# ------- CloudFormation -------

cf-validate: ## Validate CloudFormation templates
	aws cloudformation validate-template --template-body file://cloudformation/networking.yaml
	aws cloudformation validate-template --template-body file://cloudformation/data-tier.json
	aws cloudformation validate-template --template-body file://cloudformation/compute.yaml
	aws cloudformation validate-template --template-body file://cloudformation/security.yaml

# ------- Compliance Scanning -------

scan-all: ## Run Checkov on entire repo
	checkov -d terraform/ --framework terraform --output json > reports/checkov-terraform.json || true
	checkov -d helm/ --framework helm --output json > reports/checkov-helm.json || true
	checkov -d cloudformation/ --framework cloudformation --output json > reports/checkov-cloudformation.json || true
	@echo "Scan complete. Reports in reports/"

scan-tf: ## Run Checkov on Terraform only
	checkov -d terraform/ --framework terraform

scan-helm: ## Run Checkov on Helm only
	checkov -d helm/ --framework helm

scan-cf: ## Run Checkov on CloudFormation only
	checkov -d cloudformation/ --framework cloudformation
