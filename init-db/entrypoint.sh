#!/bin/bash

# Wait for SQL Server to start
echo "Waiting for SQL Server to start..."
sleep 30s

# Run the initialization script
echo "Running database initialization script..."
/opt/mssql-tools/bin/sqlcmd -S localhost -U sa -P $SA_PASSWORD -d master -i /docker-entrypoint-initdb.d/01-init-database.sql

echo "Database initialization completed!"
