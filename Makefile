# Declare all targets as phony (not associated with actual files)
.PHONY: help
.PHONY: migrate-upgrade migrate-downgrade migrate-status migrate-history migrate-new db-shell
.PHONY: docker-migrate-upgrade docker-migrate-downgrade

##### Variables
# Database configuration
# These can be overridden from the command line, e.g., make migrate-upgrade POSTGRES_USER=myuser
# Load environment variables from .env file
include .env
export

# Directory paths for backend code and database migrations
BACKEND_DIR = backend
MIGRATIONS_DIR = $(BACKEND_DIR)/migrations

##### Local Migration Commands (run on host machine)
# Apply all pending database migrations using migrate.py
migrate-upgrade:
	@echo "Applying all pending migrations..."
	@cd $(BACKEND_DIR) && python db/migrate.py upgrade

# Rollback the most recent database migration
migrate-downgrade:
	@echo "Rolling back last migration..."
	@cd $(BACKEND_DIR) && python db/migrate.py downgrade --steps 1

# Show the current migration status (which migrations are pending)
migrate-status:
	@echo "Migration status:"
	@cd $(BACKEND_DIR) && yoyo list --database postgresql://$(POSTGRES_USER):$(POSTGRES_PASSWORD)@$(POSTGRES_HOST):$(POSTGRES_PORT)/$(POSTGRES_DB) db/migrations

# Display a list of all applied migrations
migrate-history:
	@echo "Applied migrations:"
	@cd $(BACKEND_DIR) && yoyo list --database postgresql://$(POSTGRES_USER):$(POSTGRES_PASSWORD)@$(POSTGRES_HOST):$(POSTGRES_PORT)/$(POSTGRES_DB) db/migrations

# Create a new migration file with the specified message
# Requires MSG variable to be set, e.g., make migrate-new MSG='add users table'
migrate-new:
ifndef MSG
	@echo "Error: MSG variable required"
	@echo "Usage: make migrate-new MSG='description of migration'"
	@exit 1
endif
	@cd $(BACKEND_DIR) && python db/migrate.py new "$(MSG)"

# Open a PostgreSQL shell connected to the database inside the Docker container
db-shell:
	@echo "Opening database shell..."
	@docker exec -it app-db psql -U app -d appdb

# Display help information with available commands and usage examples
help:
	@echo "Database Migration Commands"
	@echo "---------------------------"
	@echo "make migrate-upgrade      - Apply all pending migrations"
	@echo "make migrate-downgrade    - Rollback the last migration"
	@echo "make migrate-status       - Show migration status"
	@echo "make migrate-history      - Show applied migrations"
	@echo "make migrate-new MSG='...'- Create new migration"
	@echo "make db-shell             - Open psql shell"