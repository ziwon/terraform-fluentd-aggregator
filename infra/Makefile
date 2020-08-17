HOME_DIR := $(dir $(lastword $(MAKEFILE_LIST)))
.SILENT: ; # no need for @
include ../.envrc
export

PHONY: tf-get-tools
tf-get-tools: # Install tools for development: # make tf-get-tools
	echo "Installing brew packages.."
	HOMEBREW_BUNDLE_NO_LOCK=1 brew bundle
	echo "Installing terrafrom.. "
ifdef TF
	mv "$(shell which terraform)" "$(shell which terraform)".bak
endif
	tfswitch -l

.check-env:
	if test "$(AWS_REGION)" = "" ; then echo "AWS_REGION not set"; exit 1; fi
	if test "$(AWS_PROFILE)" = "" ; then echo "AWS_PROFILE not set"; exit 1; fi

.check-tf-workspace:
	if test "$(shell terraform workspace show)" != "$(PROJECT)-$(ENV)" ; then \
		echo "Current workspace not match with your make arguments "; \
		exit 1; \
	fi

PHONY: tf-aws-profile
ifeq (tf-aws-profile,$(firstword $(MAKECMDGOALS)))
  ARGS := $(wordlist 2,$(words $(MAKECMDGOALS)),$(MAKECMDGOALS))
  $(eval $(ARGS):;@:)
endif
tf-aws-profile: # Configure aws profile: # make tf-aws-profile
	aws configure --profile=$(ARGS)

PHONY: tf-init
ifeq (tf-init,$(firstword $(MAKECMDGOALS)))
  ARGS := $(wordlist 2,$(words $(MAKECMDGOALS)),$(MAKECMDGOALS))
  $(eval $(ARGS):;@:)
endif
tf-init: .check-env # Initialize s3 backend: # make tf-init {project} {env}
	echo "For Debugging: TF_LOG=trace make init {project} {env}"
	$(eval PROJECT := $(shell echo $(ARGS) | cut -d ' ' -f1))
	$(eval ENV := $(shell echo $(ARGS) | cut -d ' ' -f2))
	$(HOME_DIR)/scripts/init.sh $(PROJECT) $(ENV)

PHONY: tf-vars
ifeq (tf-vars,$(firstword $(MAKECMDGOALS)))
  ARGS := $(wordlist 2,$(words $(MAKECMDGOALS)),$(MAKECMDGOALS))
  $(eval $(ARGS):;@:)
endif
tf-vars: # Create a tfvars file per environment: # VPC_ID=vpc-53a49e3b make tf-vars {project} {env}
	$(eval PROJECT := $(shell echo $(ARGS) | cut -d ' ' -f1))
	$(eval ENV := $(shell echo $(ARGS) | cut -d ' ' -f2))
	scripts/tfvars.sh $(PROJECT) $(ENV)
	cat config/$(PROJECT).$(ENV).tfvars

PHONY: tf-refresh
ifeq (tf-refresh,$(firstword $(MAKECMDGOALS)))
  ARGS := $(wordlist 2,$(words $(MAKECMDGOALS)),$(MAKECMDGOALS))
  $(eval $(ARGS):;@:)
endif
tf-refresh: .check-env # Refresh the state file with infrastructure: # make tf-refresh {project} {env}
	$(eval PROJECT := $(shell echo $(ARGS) | cut -d ' ' -f1))
	$(eval ENV := $(shell echo $(ARGS) | cut -d ' ' -f2))
	PROJECT=$(PROJECT) ENV=$(ENV) $(MAKE) .check-tf-workspace
	terraform refresh -var-file=config/$(PROJECT).$(ENV).tfvars

PHONY: tf-plan
ifeq (tf-plan,$(firstword $(MAKECMDGOALS)))
  ARGS := $(wordlist 2,$(words $(MAKECMDGOALS)),$(MAKECMDGOALS))
  $(eval $(ARGS):;@:)
endif
tf-plan: .check-env # Generate and show an execution plan: # make tf-plan {project} {env}
	$(eval PROJECT := $(shell echo $(ARGS) | cut -d ' ' -f1))
	$(eval ENV := $(shell echo $(ARGS) | cut -d ' ' -f2))
	PROJECT=$(PROJECT) ENV=$(ENV) $(MAKE) .check-tf-workspace
	terraform plan -var-file=config/$(PROJECT).$(ENV).tfvars

PHONY: tf-apply
ifeq (tf-apply,$(firstword $(MAKECMDGOALS)))
  ARGS := $(wordlist 2,$(words $(MAKECMDGOALS)),$(MAKECMDGOALS))
  $(eval $(ARGS):;@:)
endif
tf-apply: .check-env # Builds or changes infrastructure: # make tf-apply {project} {env}
	$(eval PROJECT := $(shell echo $(ARGS) | cut -d ' ' -f1))
	$(eval ENV := $(shell echo $(ARGS) | cut -d ' ' -f2))
	PROJECT=$(PROJECT) ENV=$(ENV) $(MAKE) .check-tf-workspace
	terraform apply -var-file=config/$(PROJECT).$(ENV).tfvars

PHONY: tf-import
ifeq (tf-import,$(firstword $(MAKECMDGOALS)))
  ARGS := $(wordlist 2,$(words $(MAKECMDGOALS)),$(MAKECMDGOALS))
  ARGS := $(subst :,\:,$(ARGS)) # every colons in ARN will be escaped
  $(eval $(ARGS):;@:)
endif
tf-import: .check-env # Import existing infrastructure: # make tf-import {project} {env} {resource} {arn}
	$(eval PROJECT := $(shell echo $(ARGS) | cut -d ' ' -f1))
	$(eval ENV := $(shell echo $(ARGS) | cut -d ' ' -f2))
	$(eval RESOURCE := $(shell echo $(ARGS) | cut -d ' ' -f3))
	$(eval ARN := $(shell echo $(ARGS) | cut -d ' ' -f4))
	PROJECT=$(PROJECT) ENV=$(ENV) $(MAKE) .check-tf-workspace
	terraform import -var-file=config/$(PROJECT).$(ENV).tfvars $(RESOURCE) $(ARN)

PHONY: tf-destroy
ifeq (tf-destroy,$(firstword $(MAKECMDGOALS)))
  ARGS := $(wordlist 2,$(words $(MAKECMDGOALS)),$(MAKECMDGOALS))
  $(eval $(ARGS):;@:)
endif
tf-destroy: .check-env # Destroy Terraform-managed infrastructure: # make tf-destroy {project} {env}
	$(eval PROJECT := $(shell echo $(ARGS) | cut -d ' ' -f1))
	$(eval ENV := $(shell echo $(ARGS) | cut -d ' ' -f2))
	PROJECT=$(PROJECT) ENV=$(ENV) $(MAKE) .check-tf-workspace
	terraform destroy -var-file=config/$(PROJECT).$(ENV).tfvars

tf-pull: .check-env # Get remote state to local: # make tf-pull
	rm -f ./$(STATE_DIR)/terraform.tfstate
	TF_LOG=trace terraform state pull > terraform.tfstate

PHONY: lint
ifeq (lint,$(firstword $(MAKECMDGOALS)))
  ARGS := $(wordlist 2,$(words $(MAKECMDGOALS)),$(MAKECMDGOALS))
  $(eval $(ARGS):;@:)
endif
tf-lint: # Lint the Terraform files: # make tf-lint {project} {env}
	$(eval PROJECT := $(shell echo $(ARGS) | cut -d ' ' -f1))
	$(eval ENV := $(shell echo $(ARGS) | cut -d ' ' -f2))
	scripts/tflint.sh $(PROJECT) $(ENV)

PHONY: vpc-id
ifeq (vpc-id,$(firstword $(MAKECMDGOALS)))
  ARGS := $(wordlist 2,$(words $(MAKECMDGOALS)),$(MAKECMDGOALS))
  $(eval $(ARGS):;@:)
endif
tf-vpc-id: # Show the VPC ID with the given group: # make tf-vpc-id {group}
	aws ec2 describe-vpcs --filters Name=tag:Group,Values=$(ARGS) | \
		jq -r ".Vpcs[].VpcId"

PHONY: tf-clean
tf-clean: # Clean the Terraform-generated files: # make tf-clean
	rm -rf $(STATE_DIR)
	rm -rf terraform.tfstate.d
	rm -rf *.zip
	rm -rf config/*.tflint

PHONY: help
help: # Show this help message: # make help
	echo "Usage: make [command] [args]"
	grep -E '^[a-zA-Z_-]+:.*?# .*$$' $(MAKEFILE_LIST) | sort | sed -e 's/: \([a-z\.\-][^ ]*\) #/: #/g' | awk 'BEGIN {FS = ": # "}; {printf "\t\033[36m%-32s\033[0m \033[33m%-45s\033[0m (e.g. \033[32m%s\033[0m)\n", $$1, $$2, $$3}'

.DEFAULT_GOAL := help
