# Makefile for CyberLab Terraform Infrastructure
# Simplifies common Terraform operations

.PHONY: help init plan apply destroy clean status validate fmt check install-providers dev prod

# Default target
.DEFAULT_GOAL := help

# Variables
ENV ?= dev
TF_VAR_FILE = environments/$(ENV)/terraform.tfvars

# Colors for output
BLUE := \033[0;34m
GREEN := \033[0;32m
YELLOW := \033[0;33m
RED := \033[0;31m
NC := \033[0m # No Color

help: ## Show this help message
	@echo "$(BLUE)CyberLab Terraform Infrastructure$(NC)"
	@echo ""
	@echo "$(GREEN)Usage:$(NC)"
	@echo "  make [target] [ENV=dev|prod]"
	@echo ""
	@echo "$(GREEN)Targets:$(NC)"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  $(BLUE)%-20s$(NC) %s\n", $$1, $$2}'
	@echo ""
	@echo "$(GREEN)Examples:$(NC)"
	@echo "  make init              # Initialize Terraform"
	@echo "  make plan ENV=dev      # Plan dev environment"
	@echo "  make apply ENV=prod    # Apply prod environment"
	@echo "  make destroy ENV=dev   # Destroy dev environment"

init: ## Initialize Terraform providers and modules
	@echo "$(BLUE)Initializing Terraform...$(NC)"
	terraform init
	@echo "$(GREEN)Terraform initialized successfully$(NC)"

validate: ## Validate Terraform configuration
	@echo "$(BLUE)Validating Terraform configuration...$(NC)"
	terraform validate
	@echo "$(GREEN)Configuration is valid$(NC)"

fmt: ## Format Terraform files
	@echo "$(BLUE)Formatting Terraform files...$(NC)"
	terraform fmt -recursive
	@echo "$(GREEN)Files formatted$(NC)"

check: validate fmt ## Run validation and formatting checks
	@echo "$(GREEN)All checks passed$(NC)"

plan: ## Generate and show execution plan
	@echo "$(BLUE)Planning infrastructure for $(ENV) environment...$(NC)"
	@if [ -f "$(TF_VAR_FILE)" ]; then \
		terraform plan -var-file="$(TF_VAR_FILE)"; \
	else \
		echo "$(YELLOW)Warning: $(TF_VAR_FILE) not found, using defaults$(NC)"; \
		terraform plan; \
	fi

apply: ## Apply infrastructure changes
	@echo "$(BLUE)Applying infrastructure for $(ENV) environment...$(NC)"
	@if [ -f "$(TF_VAR_FILE)" ]; then \
		terraform apply -var-file="$(TF_VAR_FILE)"; \
	else \
		echo "$(YELLOW)Warning: $(TF_VAR_FILE) not found, using defaults$(NC)"; \
		terraform apply; \
	fi

apply-auto: ## Apply without confirmation (use with caution)
	@echo "$(YELLOW)Auto-applying infrastructure for $(ENV) environment...$(NC)"
	@if [ -f "$(TF_VAR_FILE)" ]; then \
		terraform apply -auto-approve -var-file="$(TF_VAR_FILE)"; \
	else \
		terraform apply -auto-approve; \
	fi

destroy: ## Destroy infrastructure
	@echo "$(RED)Destroying infrastructure for $(ENV) environment...$(NC)"
	@if [ -f "$(TF_VAR_FILE)" ]; then \
		terraform destroy -var-file="$(TF_VAR_FILE)"; \
	else \
		terraform destroy; \
	fi

destroy-auto: ## Destroy without confirmation (use with extreme caution)
	@echo "$(RED)Auto-destroying infrastructure for $(ENV) environment...$(NC)"
	@if [ -f "$(TF_VAR_FILE)" ]; then \
		terraform destroy -auto-approve -var-file="$(TF_VAR_FILE)"; \
	else \
		terraform destroy -auto-approve; \
	fi

status: ## Show current infrastructure status
	@echo "$(BLUE)Current Infrastructure Status:$(NC)"
	@terraform show
	@echo ""
	@echo "$(BLUE)Docker Containers:$(NC)"
	@docker ps --filter "label=project=cyberlab" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" 2>/dev/null || echo "No Docker containers found"

output: ## Show Terraform outputs
	@echo "$(BLUE)Terraform Outputs:$(NC)"
	@terraform output

refresh: ## Refresh Terraform state
	@echo "$(BLUE)Refreshing Terraform state...$(NC)"
	terraform refresh

state-list: ## List resources in state
	@echo "$(BLUE)Resources in Terraform state:$(NC)"
	@terraform state list

clean: ## Clean Terraform files
	@echo "$(YELLOW)Cleaning Terraform files...$(NC)"
	rm -rf .terraform
	rm -f .terraform.lock.hcl
	rm -f terraform.tfstate*
	@echo "$(GREEN)Cleaned successfully$(NC)"

install-providers: ## Install required Terraform providers
	@echo "$(BLUE)Installing Terraform providers...$(NC)"
	terraform providers
	@echo "$(GREEN)Providers installed$(NC)"

# Environment shortcuts
dev: ## Switch to dev environment and plan
	@echo "$(BLUE)Using development environment$(NC)"
	$(MAKE) plan ENV=dev

prod: ## Switch to prod environment and plan
	@echo "$(BLUE)Using production environment$(NC)"
	$(MAKE) plan ENV=prod

# Docker helpers
docker-ps: ## Show running Docker containers
	@echo "$(BLUE)Running Docker containers:$(NC)"
	@docker ps --filter "label=project=cyberlab"

docker-logs: ## Show logs for all containers
	@echo "$(BLUE)Docker container logs:$(NC)"
	@docker ps -q --filter "label=project=cyberlab" | xargs -I {} docker logs --tail 50 {}

docker-clean: ## Remove all project Docker resources
	@echo "$(YELLOW)Removing Docker resources...$(NC)"
	@docker ps -aq --filter "label=project=cyberlab" | xargs -r docker rm -f
	@docker network ls --filter "label=project=cyberlab" -q | xargs -r docker network rm
	@docker volume ls --filter "name=cyberlab" -q | xargs -r docker volume rm
	@echo "$(GREEN)Docker resources cleaned$(NC)"

# VMware helpers
vmware-status: ## Show VMware VMs status (requires vmrun)
	@echo "$(BLUE)VMware VMs:$(NC)"
	@vmrun list 2>/dev/null || echo "vmrun not found or no VMs running"

# VirtualBox helpers
vbox-status: ## Show VirtualBox VMs status
	@echo "$(BLUE)VirtualBox VMs:$(NC)"
	@VBoxManage list runningvms 2>/dev/null || echo "VirtualBox not found or no VMs running"

# Network helpers
network-test: ## Test network connectivity
	@echo "$(BLUE)Testing network connectivity...$(NC)"
	@docker network ls --filter "label=project=cyberlab"
	@echo ""
	@echo "$(BLUE)Testing Wazuh Dashboard:$(NC)"
	@curl -k -s -o /dev/null -w "Status: %{http_code}\n" https://localhost:5601 || echo "Not accessible"

# Backup and restore
backup: ## Backup Terraform state
	@echo "$(BLUE)Backing up Terraform state...$(NC)"
	@mkdir -p backups
	@cp terraform.tfstate backups/terraform.tfstate.$(shell date +%Y%m%d-%H%M%S)
	@echo "$(GREEN)Backup created$(NC)"

# Documentation
docs: ## Generate documentation
	@echo "$(BLUE)Generating Terraform documentation...$(NC)"
	@terraform-docs markdown table . > TERRAFORM_DOCS.md 2>/dev/null || echo "terraform-docs not installed"

# Quick start
quickstart: init plan ## Quick start: init and plan
	@echo "$(GREEN)Ready to deploy! Run 'make apply' to deploy infrastructure$(NC)"

# Full deployment
deploy: init apply output ## Full deployment: init, apply, and show outputs
	@echo "$(GREEN)Deployment complete!$(NC)"

# Full teardown
teardown: destroy clean ## Full teardown: destroy and clean
	@echo "$(GREEN)Teardown complete!$(NC)"
