#!/bin/bash

# This script will dump each table in a sqlite 3 database

# Check if the first command-line argument is empty
if [ -z "$1" ]; then
  echo "Error: No filename provided. Exiting..."
  exit 1
fi

# Set the name of the SQLite database file
DB_NAME=$1

if [ "$(head -c 15 $DB_NAME |strings)" == "SQLite format 3" ]
then
    # List all tables
    echo "List of tables:"
    sqlite3 $DB_NAME "SELECT name FROM sqlite_master WHERE type='table';"

    # Retrieve all rows from each table
    tables=$(sqlite3 $DB_NAME "SELECT name FROM sqlite_master WHERE type='table';")
    echo "Retrieving data from tables:"
    for table in $tables; do
        echo "Table: $table"
        sqlite3 $DB_NAME "SELECT * FROM $table;"
    done
    echo ""
else
    echo "Error: The file is not a sqlite database."
    exit 1
fi
