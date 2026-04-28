# scripts

CLI helpers for working with this Looker project.

## mysql_query.py

Query the MySQL `ota` database that backs this Looker project. Used by agents (and humans) to inspect tables like `ota.optimizer_candidates`, `ota.optimizer_attempts`, `ota.optimizer_candidate_tags`, and to validate query patterns before committing them to LookML.

> Access is **read-only**. The script is intended for inspecting schemas, validating query shapes, and sanity-checking aggregates against real data. Never use it to modify data.

### Setup

1. Create a virtualenv and install requirements:

   ```bash
   python3 -m venv .venv
   source .venv/bin/activate
   pip install -r requirements.txt
   ```

2. Copy `.env.example` to `.env` and fill in credentials:

   ```bash
   cp .env.example .env
   # then edit .env and fill MYSQL_HOST / MYSQL_USER / MYSQL_PASSWORD / MYSQL_DATABASE
   ```

3. Export the variables into your shell. The script reads them from `os.environ`:

   ```bash
   set -a && source .env && set +a
   ```

   (Or use a tool like `direnv` / `dotenv` to do this automatically.)

### Usage

```bash
# Run an ad-hoc query
python scripts/mysql_query.py query "SELECT count(*) FROM ota.optimizer_candidates WHERE created_at > now() - interval 1 day"

# List tables in a database (defaults to MYSQL_DATABASE)
python scripts/mysql_query.py tables ota

# Describe a table's columns (uses INFORMATION_SCHEMA)
python scripts/mysql_query.py describe optimizer_candidates ota

# Run a date-windowed query in chunks; numeric columns are summed across chunks
python scripts/mysql_query.py batch \
  --start 2026-03-01 --end 2026-03-31 --chunk-days 1 \
  "SELECT DATE(created_at) AS d, count(*) AS n
     FROM ota.optimizer_candidates
    WHERE created_at BETWEEN '{start}' AND '{end}'
    GROUP BY d"
```

### Subcommands

| Subcommand | Purpose |
|-----------|---------|
| `query <sql>` | Run any SQL statement and print the result as a table. |
| `tables [db]` | List tables in `db` (or `MYSQL_DATABASE`) with engine, approx row count, and size. |
| `describe <table> [db]` | Print columns, types, nullability, default, key type, and column comment. |
| `batch <sql> --start --end [--chunk-days N]` | Run the same query repeatedly across date windows; numeric columns are summed and non-numeric columns are treated as group keys. Heavy queries that time out on a long range often succeed when chunked. |

### Notes

- Connection settings come from environment variables (`MYSQL_HOST`, `MYSQL_PORT`, `MYSQL_USER`, `MYSQL_PASSWORD`, `MYSQL_DATABASE`, optional `MYSQL_SSL=1`).
- The `.env` file is gitignored. Never commit credentials.
- Query timeout is configured to 600 seconds. For long aggregations across large date ranges, prefer the `batch` subcommand.
- Agent usage is documented in `.cursor/rules/mysql-query-tool.mdc`.
