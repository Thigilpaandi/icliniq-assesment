
#!/usr/bin/env bash
set -euo pipefail

: "${DB_HOST:?missing}"
: "${DB_NAME:?missing}"
: "${DB_USER:?missing}"
: "${DB_PASSWORD:?missing}"
: "${DB_PORT:=5432}"

export PGPASSWORD="$DB_PASSWORD"

psql -h "$DB_HOST" -U "$DB_USER" -d "$DB_NAME" -p "$DB_PORT" <<'SQL'
INSERT INTO items(name) VALUES ('alpha'), ('beta'), ('gamma') ON CONFLICT DO NOTHING;
SQL

echo "Seed complete"
