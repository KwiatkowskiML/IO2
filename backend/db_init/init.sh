#!/bin/sh

# This script waits for the database to be ready, then applies SQL scripts.
# Environment variables like PGPASSWORD, DB_HOST, DB_USER, DB_NAME are expected to be set.

set -e

# Wait for the database to be available
# Using a simple sleep for Docker Compose, but could be a more robust check
echo "Waiting for database at $DB_HOST:$DB_PORT..."
# A more robust wait loop
until psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -c '\q'; do
  >&2 echo "Postgres is unavailable - sleeping"
  sleep 1
done
>&2 echo "Postgres is up - executing command"


# Apply all SQL files in the /sql directory
for f in /app/sql/*.sql; do
  echo "Applying SQL file $f..."
  psql -v ON_ERROR_STOP=1 --host "$DB_HOST" --port "$DB_PORT" --username "$DB_USER" --dbname "$DB_NAME" -f "$f"
done

echo "Database initialization complete."
