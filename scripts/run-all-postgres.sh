#!/usr/bin/env bash
# Runs every PostgreSQL lesson script against a freshly loaded sample database.
# Any SQL error fails the run, so this doubles as a test of the tutorial.
#
# Usage:
#   PGHOST=localhost PGPORT=5432 PGUSER=postgres PGPASSWORD=... PGDATABASE=sqltutorial \
#     scripts/run-all-postgres.sh            # run all lessons
#   scripts/run-all-postgres.sh 03-advanced  # run only lessons under a folder
#
# Every lesson .sql file is run except vendor-specific ones
# (files whose names start with mysql, oracle or sqlite).

set -euo pipefail
cd "$(dirname "$0")/.."

filter="${1:-.}"
psql_run() { psql -X -q -v ON_ERROR_STOP=1 "$@" > /dev/null; }

reset_db() {
    psql_run -f sample-db/schema.sql
    psql_run -f sample-db/seed.sql
}

errfile=$(mktemp)
trap 'rm -f "$errfile"' EXIT
failed=0
while IFS= read -r f; do
    reset_db
    if psql_run -f "$f" 2> "$errfile"; then
        echo "ok    $f"
    else
        echo "FAIL  $f"; sed 's/^/      /' "$errfile"
        failed=1
    fi
done < <(find "$filter" -type f -name '*.sql' \
            ! -path '*sample-db/*' ! -name 'mysql*' ! -name 'oracle*' ! -name 'sqlite*' | sort)

exit $failed
