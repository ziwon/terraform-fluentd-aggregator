HOME_DIR := $(dir $(lastword $(MAKEFILE_LIST)))
.SILENT: ; # no need for @
include .envrc
export

include $(HOME_DIR)/swarm.mk
include $(HOME_DIR)/docker.mk

PHONY: envrc-local
envrc-local: # Change environment to local development: # make envrc-local
	ln -fs .envrc.local .envrc
	direnv allow

PHONY: envrc-prod
envrc-prod: # Change environment to prod development: # make envrc-prod
	ln -fs .envrc.prod .envrc
	direnv allow

PHONY: help
help: # Show this help message: # make help
	echo "Usage: make [command] [args]"
	grep -E '^[a-zA-Z_-]+:.*?# .*$$' $(MAKEFILE_LIST) | sort | sed -e 's/: \([a-z\.\-][^ ]*\) #/: #/g' | awk 'BEGIN {FS = ": # "}; {printf "\t\033[36m%-32s\033[0m \033[33m%-45s\033[0m (e.g. \033[32m%s\033[0m)\n", $$1, $$2, $$3}'

.DEFAULT_GOAL := help
