# Code9 Group — local WordPress stack management
# Usage: make <target>   (run from the site/ directory)

COMPOSE = docker compose
WPCLI   = $(COMPOSE) run --user 1000:1000 --rm wpcli wp
STAMP   = $(shell date +%Y%m%d-%H%M%S)

.PHONY: help up down restart logs ps build wpcli shell db-shell \
        backup backup-db backup-files flush-cache reset-admin-pass status

help: ## Show this help
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | \
	  awk 'BEGIN{FS=":.*?## "}{printf "  \033[36m%-16s\033[0m %s\n", $$1, $$2}'

up: ## Start the whole stack (detached)
	$(COMPOSE) up -d
	@echo "Site:  http://localhost:8082   Admin: http://localhost:8082/wp-admin"

down: ## Stop and remove containers (keeps DB volume + files)
	$(COMPOSE) down

restart: ## Restart all services
	$(COMPOSE) restart

build: ## Rebuild the PHP image
	$(COMPOSE) build wordpress

logs: ## Tail logs from all services
	$(COMPOSE) logs -f --tail=100

ps status: ## Show container status
	$(COMPOSE) ps

shell: ## Shell into the WordPress (php-fpm) container
	$(COMPOSE) exec wordpress bash

db-shell: ## Open a MariaDB shell
	$(COMPOSE) exec db sh -c 'mariadb -u root -p"$$MARIADB_ROOT_PASSWORD" $$MARIADB_DATABASE'

wpcli: ## Run a wp-cli command, e.g. make wpcli CMD="plugin list"
	$(WPCLI) $(CMD)

flush-cache: ## Regenerate Elementor CSS and flush WP caches
	$(WPCLI) elementor flush_css
	$(WPCLI) transient delete --all
	$(WPCLI) cache flush

reset-admin-pass: ## Reset an admin password: make reset-admin-pass USER=Code-9-Group PASS=newpass
	$(WPCLI) user update "$(USER)" --user_pass="$(PASS)"

backup: backup-db backup-files ## Full backup (database + files)

backup-db: ## Dump the database to ./backups/
	@mkdir -p backups
	$(COMPOSE) exec -T db sh -c 'mariadb-dump -u root -p"$$MARIADB_ROOT_PASSWORD" --single-transaction $$MARIADB_DATABASE' \
	  | gzip > backups/db-$(STAMP).sql.gz
	@echo "Wrote backups/db-$(STAMP).sql.gz"

backup-files: ## Archive wp-content to ./backups/
	@mkdir -p backups
	tar -czf backups/wp-content-$(STAMP).tar.gz -C wordpress wp-content
	@echo "Wrote backups/wp-content-$(STAMP).tar.gz"
