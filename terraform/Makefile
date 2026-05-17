.PHONY: help init plan apply destroy fmt validate

ENVIRONMENT ?= dev
TF_DIR := environments/$(ENVIRONMENT)
TF_VARS := $(TF_DIR)/terraform.tfvars

help:
	@echo "Terraform - Kube-News Infrastructure"
	@echo ""
	@echo "Available commands:"
	@echo "  make init       - Initialize Terraform (default: dev)"
	@echo "  make plan       - Plan infrastructure changes (default: dev)"
	@echo "  make apply      - Apply infrastructure changes (default: dev)"
	@echo "  make destroy    - Destroy infrastructure (default: dev)"
	@echo "  make fmt        - Format Terraform files"
	@echo "  make validate   - Validate Terraform configuration"
	@echo "  make outputs    - Show Terraform outputs"
	@echo ""
	@echo "Usage:"
	@echo "  make init ENVIRONMENT=dev"
	@echo "  make plan ENVIRONMENT=prod"
	@echo "  make apply ENVIRONMENT=prod"
	@echo ""

init:
	@cd $(TF_DIR) && \
	terraform init && \
	echo "✓ Terraform initialized for $(ENVIRONMENT) environment"

plan:
	@if [ ! -f "$(TF_VARS)" ]; then \
		echo "✗ File not found: $(TF_VARS)"; \
		exit 1; \
	fi
	@cd $(TF_DIR) && \
	terraform plan -var-file=$(notdir $(TF_VARS)) -out=tfplan && \
	echo "✓ Plan created for $(ENVIRONMENT) environment"

apply: plan
	@cd $(TF_DIR) && \
	terraform apply tfplan && \
	echo "✓ Infrastructure deployed to $(ENVIRONMENT) environment"

destroy:
	@echo "⚠️  WARNING: Destroying infrastructure in $(ENVIRONMENT) environment!"
	@echo "Press Ctrl+C to cancel (5 seconds)..."
	@sleep 5
	@cd $(TF_DIR) && \
	terraform destroy -var-file=$(notdir $(TF_VARS)) -auto-approve && \
	echo "✓ Infrastructure destroyed in $(ENVIRONMENT) environment"

fmt:
	@terraform fmt -recursive . && \
	echo "✓ Terraform files formatted"

validate:
	@terraform validate && \
	echo "✓ Terraform configuration is valid"

outputs:
	@cd $(TF_DIR) && \
	terraform output

dev-init:
	@$(MAKE) init ENVIRONMENT=dev

dev-plan:
	@$(MAKE) plan ENVIRONMENT=dev

dev-apply:
	@$(MAKE) apply ENVIRONMENT=dev

dev-destroy:
	@$(MAKE) destroy ENVIRONMENT=dev

prod-init:
	@$(MAKE) init ENVIRONMENT=prod

prod-plan:
	@$(MAKE) plan ENVIRONMENT=prod

prod-apply:
	@$(MAKE) apply ENVIRONMENT=prod

prod-destroy:
	@$(MAKE) destroy ENVIRONMENT=prod
