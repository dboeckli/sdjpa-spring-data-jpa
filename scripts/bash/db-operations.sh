#!/bin/bash

# db-operations.sh - Script for database operations
#
# This script provides functionality for initializing, backing up, and restoring
# the MySQL database used by the application.

# Safer Bash scripting options
set -o pipefail # Don't hide errors within pipes
set -o nounset  # Abort on unbound variable
set -o errexit  # Abort on nonzero exit status

# Default values
DB_HOST="localhost"
DB_PORT="3306"
DB_NAME="bookdb"
DB_USER="bookadmin"
DB_PASSWORD="password"
BACKUP_DIR="./db-backups"
INIT_SCRIPT="./src/scripts/init-mysql.sql"
OPERATION=""

# Function to display usage information
function show_usage {
    echo "Usage: $0 [options] <operation>"
    echo "Operations:"
    echo "  init       Initialize the database using the init script"
    echo "  backup     Backup the database"
    echo "  restore    Restore the database from a backup"
    echo "  status     Check database connection status"
    echo "Options:"
    echo "  -h, --host HOST          Database host [default: localhost]"
    echo "  -P, --port PORT          Database port [default: 3306]"
    echo "  -d, --database DB_NAME   Database name [default: bookdb]"
    echo "  -u, --user USER          Database user [default: bookadmin]"
    echo "  -p, --password PASSWORD  Database password [default: password]"
    echo "  -b, --backup-dir DIR     Backup directory [default: ./db-backups]"
    echo "  -i, --init-script FILE   Init script [default: ./src/scripts/init-mysql.sql]"
    echo "  -f, --file FILE          Backup file to restore (for restore operation)"
    echo "  --help                   Show this help message"
    exit 1
}

# Parse command line arguments
BACKUP_FILE=""
while [[ $# -gt 0 ]]; do
    case "$1" in
        -h|--host)
            DB_HOST="$2"
            shift 2
            ;;
        -P|--port)
            DB_PORT="$2"
            shift 2
            ;;
        -d|--database)
            DB_NAME="$2"
            shift 2
            ;;
        -u|--user)
            DB_USER="$2"
            shift 2
            ;;
        -p|--password)
            DB_PASSWORD="$2"
            shift 2
            ;;
        -b|--backup-dir)
            BACKUP_DIR="$2"
            shift 2
            ;;
        -i|--init-script)
            INIT_SCRIPT="$2"
            shift 2
            ;;
        -f|--file)
            BACKUP_FILE="$2"
            shift 2
            ;;
        init|backup|restore|status)
            OPERATION="$1"
            shift
            ;;
        --help)
            show_usage
            ;;
        *)
            echo "Unknown option: $1"
            show_usage
            ;;
    esac
done

# Check if operation is provided
if [ -z "$OPERATION" ]; then
    echo "Error: No operation specified."
    show_usage
fi

# Function to check MySQL connection
function check_mysql_connection {
    echo "Checking MySQL connection..."
    if mysql -h "$DB_HOST" -P "$DB_PORT" -u "$DB_USER" -p"$DB_PASSWORD" -e "SELECT 1" &>/dev/null; then
        echo "MySQL connection successful."
        return 0
    else
        echo "Error: Could not connect to MySQL server."
        return 1
    fi
}

# Function to initialize the database
function initialize_database {
    echo "Initializing database using script: $INIT_SCRIPT"
    
    if [ ! -f "$INIT_SCRIPT" ]; then
        echo "Error: Init script not found: $INIT_SCRIPT"
        exit 1
    fi
    
    # Execute the init script
    mysql -h "$DB_HOST" -P "$DB_PORT" -u "$DB_USER" -p"$DB_PASSWORD" < "$INIT_SCRIPT"
    
    if [ $? -eq 0 ]; then
        echo "Database initialized successfully."
    else
        echo "Error: Failed to initialize database."
        exit 1
    fi
}

# Function to backup the database
function backup_database {
    # Create backup directory if it doesn't exist
    mkdir -p "$BACKUP_DIR"
    
    # Generate backup filename with timestamp
    TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
    BACKUP_FILE="$BACKUP_DIR/${DB_NAME}_${TIMESTAMP}.sql"
    
    echo "Backing up database to: $BACKUP_FILE"
    
    # Perform the backup
    mysqldump -h "$DB_HOST" -P "$DB_PORT" -u "$DB_USER" -p"$DB_PASSWORD" --databases "$DB_NAME" > "$BACKUP_FILE"
    
    if [ $? -eq 0 ]; then
        echo "Database backup completed successfully."
    else
        echo "Error: Database backup failed."
        exit 1
    fi
}

# Function to restore the database
function restore_database {
    if [ -z "$BACKUP_FILE" ]; then
        echo "Error: No backup file specified. Use -f or --file option."
        exit 1
    fi
    
    if [ ! -f "$BACKUP_FILE" ]; then
        echo "Error: Backup file not found: $BACKUP_FILE"
        exit 1
    fi
    
    echo "Restoring database from: $BACKUP_FILE"
    
    # Perform the restore
    mysql -h "$DB_HOST" -P "$DB_PORT" -u "$DB_USER" -p"$DB_PASSWORD" < "$BACKUP_FILE"
    
    if [ $? -eq 0 ]; then
        echo "Database restore completed successfully."
    else
        echo "Error: Database restore failed."
        exit 1
    fi
}

# Execute the requested operation
case "$OPERATION" in
    init)
        initialize_database
        ;;
    backup)
        check_mysql_connection && backup_database
        ;;
    restore)
        check_mysql_connection && restore_database
        ;;
    status)
        check_mysql_connection
        ;;
    *)
        echo "Error: Invalid operation: $OPERATION"
        show_usage
        ;;
esac