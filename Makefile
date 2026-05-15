SHELL := /bin/bash
.SHELLFLAGS := -eu -o pipefail -c
.DEFAULT_GOAL := help

# Compose files; later phases append more
COMPOSE := docker compose

.PHONY: help
help: ## Show this help
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) \
		| awk 'BEGIN{FS=":.*?## "}{printf "  \033[36m%-20s\033[0m %s\n", $$1, $$2}'

.PHONY: up-core
up-core: ## Bring up the core stack (Phase 0: Postgres only)
	@test -f .env || (echo ".env missing — copy .env.example first" && exit 1)
	$(COMPOSE) up -d postgres
	@$(COMPOSE) ps

.PHONY: down
down: ## Tear down all running compose services (preserves volumes)
	$(COMPOSE) down

.PHONY: nuke
nuke: ## Tear down AND remove volumes (DATA LOSS)
	$(COMPOSE) down -v

.PHONY: logs
logs: ## Tail logs of all running services
	$(COMPOSE) logs -f --tail=100

.PHONY: ps
ps: ## Show running compose services
	$(COMPOSE) ps

.PHONY: lint
lint: ## Run all linters (pre-commit on all files)
	pre-commit run --all-files

.PHONY: psql
psql: ## Open a psql shell to Postgres
	$(COMPOSE) exec postgres psql -U $${POSTGRES_USER:-ecom} -d $${POSTGRES_DB:-ecom}
