#!/usr/bin/env python3
"""
Database migration management script using yoyo-migrations.
Provides simple commands similar to Alembic.
"""

import os
import subprocess
import sys
from datetime import datetime
from pathlib import Path

from dotenv import load_dotenv

# Load environment variables from .env file
load_dotenv()


def build_database_url():

    # Build from individual components
    host = os.getenv("POSTGRES_HOST", "host")
    port = os.getenv("POSTGRES_PORT", "9999")
    user = os.getenv("POSTGRES_USER", "user")
    password = os.getenv("POSTGRES_PASSWORD", "password")
    database = os.getenv("POSTGRES_DB", "db")

    return f"postgresql://{user}:{password}@{host}:{port}/{database}"


def get_migrations_dir():
    """Get the migrations directory path."""
    script_dir = Path(__file__).parent
    migrations_dir = script_dir / "migrations"

    if not migrations_dir.exists():
        print(f"Error: Migrations directory not found at {migrations_dir}")
        sys.exit(1)

    return str(migrations_dir)


def run_yoyo_command(command, *args):
    """Run a yoyo-migrations command."""
    database_url = build_database_url()
    migrations_dir = get_migrations_dir()

    cmd = ["yoyo", command, "--database", database_url, migrations_dir]
    cmd.extend(args)

    print(f"Running: {' '.join(cmd)}")
    print(f"Database: {database_url}")
    print("-" * 60)

    try:
        result = subprocess.run(cmd, check=True)
        return result.returncode
    except subprocess.CalledProcessError as e:
        print(f"\nError: Migration command failed with exit code {e.returncode}")
        sys.exit(e.returncode)
    except FileNotFoundError:
        print("\nError: yoyo-migrations not found. Install it with:")
        print("  pip install yoyo-migrations")
        sys.exit(1)


def upgrade():
    """Apply all pending migrations (like alembic upgrade head)."""
    print("Applying all pending migrations...")
    run_yoyo_command("apply", "--batch")


def downgrade():
    """Rollback the last applied migration (like alembic downgrade -1)."""
    print("Rolling back last migration...")
    run_yoyo_command("rollback", "--batch")


def new(message):
    """Create a new migration file."""
    if not message:
        print("Error: Migration message required")
        print("Usage: python migrate.py new 'add new column'")
        sys.exit(1)

    migrations_dir = get_migrations_dir()

    # Get next index
    existing = sorted([f for f in Path(migrations_dir).glob("*.sql")])
    if existing:
        last_file = existing[-1].stem.replace(".rollback", "")
        last_index = int(last_file.split("_")[0])
        next_index = last_index + 1
    else:
        next_index = 1

    # Format: 001_050126_description
    date_str = datetime.now().strftime("%d%m%y")
    safe_message = message.lower().replace(" ", "_").replace("-", "_")
    filename = f"{next_index:03d}_{date_str}_{safe_message}"

    # Create .sql migration file
    sql_filepath = Path(migrations_dir) / f"{filename}.sql"
    rollback_filepath = Path(migrations_dir) / f"{filename}.rollback.sql"

    # Determine depends
    depends = ""
    if existing:
        last_migration = existing[-1].stem.replace(".rollback", "")
        depends = f"-- depends: {last_migration}\n"

    sql_template = f"""-- {message}
{depends}
-- Migration SQL goes here


"""

    rollback_template = f"""-- Rollback for: {message}
{depends}
-- Rollback SQL goes here


"""

    sql_filepath.write_text(sql_template)
    rollback_filepath.write_text(rollback_template)
    print(f"Created new migration: {filename}.sql")
    print(f"Created rollback file: {filename}.rollback.sql")


def print_help():
    """Print help message."""
    help_text = """
Database Migration Manager
--------------------------

Usage: python migrate.py <command> [options]

Commands:
  upgrade     Apply all pending migrations (like alembic upgrade head)
  downgrade   Rollback the last applied migration (like alembic downgrade -1)
  new <msg>   Create a new migration file with message
  help        Show this help message

Note: Use 'make migrate-status' and 'make migrate-history' from the Makefile
      for status and history commands.

Environment Variables:
  POSTGRES_HOST      Database host (default: localhost)
  POSTGRES_PORT      Database port (default: 5432)
  POSTGRES_USER      Database user
  POSTGRES_PASSWORD  Database password
  POSTGRES_DB        Database name

Examples:
  python migrate.py upgrade
  python migrate.py downgrade
  python migrate.py new "add user profile table"
"""
    print(help_text)


def main():
    """Main entry point."""
    if len(sys.argv) < 2:
        print_help()
        sys.exit(1)

    command = sys.argv[1].lower()

    commands = {
        "upgrade": upgrade,
        "up": upgrade,
        "downgrade": downgrade,
        "down": downgrade,
        "help": print_help,
        "-h": print_help,
        "--help": print_help,
    }

    if command == "new":
        if len(sys.argv) < 3:
            print("Error: Migration message required")
            print("Usage: python migrate.py new 'add new column'")
            sys.exit(1)
        new(" ".join(sys.argv[2:]))
    elif command in commands:
        commands[command]()
    else:
        print(f"Error: Unknown command '{command}'")
        print_help()
        sys.exit(1)


if __name__ == "__main__":
    main()
