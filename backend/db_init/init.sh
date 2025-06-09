#!/bin/sh

# This script waits for the database to be ready, then applies SQL scripts.
# Environment variables like PGPASSWORD, DB_HOST, DB_USER, DB_NAME are expected to be set.
# A special variable, DB_RESET=true, will trigger a full wipe of the public schema.

set -e

echo "Waiting for database at $DB_HOST:$DB_PORT..."
until psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -c '\q'; do
  >&2 echo "Postgres is unavailable - sleeping"
  sleep 1
done
>&2 echo "Postgres is up - continuing."

if [ "${DB_RESET}" = "true" ]; then
  echo "DB_RESET is true. Wiping public schema..."
  psql -v ON_ERROR_STOP=1 --host "$DB_HOST" --port "$DB_PORT" --username "$DB_USER" --dbname "$DB_NAME" -c "DROP SCHEMA public CASCADE; CREATE SCHEMA public;"
  echo "Public schema wiped and recreated."
else
  echo "DB_RESET is not set to 'true'. Skipping database wipe."
fi

# Apply all SQL files in the /sql directory
for f in /app/sql/*.sql; do
  echo "Applying SQL file $f..."
  psql -v ON_ERROR_STOP=1 --host "$DB_HOST" --port "$DB_PORT" --username "$DB_USER" --dbname "$DB_NAME" -f "$f"
done

echo "Database initialization complete."
