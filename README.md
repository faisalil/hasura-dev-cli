# hasura-dev-cli

Docker-free local Hasura v2 development runtime.

`hasura-dev` is a Hasura CLI build that adds local runtime commands so you can run Hasura + Postgres without Docker while keeping familiar Hasura workflows (`deploy`, `migrate`, `metadata`, `seed`, `console`).

Minimum recommended version: `v0.1.3`.

## Who this is for

- Teams currently running Hasura v2 with Docker Compose.
- Developers who want a native local runtime for day-to-day Hasura development.
- Existing Hasura project users who want to keep migrations/metadata/seeds workflows unchanged.

## Prerequisites

- Supported host platforms for embedded Postgres mode:
  - `darwin-arm64`
  - `linux-amd64`
  - `linux-arm64`
- `curl` installed (used for quick health checks).
- Optional: `psql` for manual database inspection.
- Optional for project bootstrap: a Hasura project with `config.yaml`.

Security default:
- Runtime binds to localhost (`127.0.0.1`) by default.

## Install and upgrade

### Homebrew (recommended)

```bash
brew tap faisalil/hasura-dev-cli https://github.com/faisalil/hasura-dev-cli
brew install faisalil/hasura-dev-cli/hasura-dev
```

Upgrade:

```bash
brew update
brew upgrade hasura-dev
```

### Direct binary (fallback)

1. Download the correct tarball from:
   - `https://github.com/faisalil/hasura-dev-cli/releases`
2. Extract and move `hasura-dev` into your `PATH`.

Example for macOS arm64:

```bash
curl -L -o hasura-dev-darwin-arm64.tar.gz \
  https://github.com/faisalil/hasura-dev-cli/releases/download/v0.1.3/hasura-dev-darwin-arm64.tar.gz
tar -xzf hasura-dev-darwin-arm64.tar.gz
chmod +x hasura-dev
sudo mv hasura-dev /usr/local/bin/hasura-dev
```

### Verify install

```bash
hasura-dev version
```

Expected fields include:
- `version`
- `build_date_local`
- `build_age`

## Quick start (no existing project)

Start a local Hasura + embedded Postgres runtime in detached mode:

```bash
hasura-dev server start-dev --detach --admin-secret <admin-secret>
```

Check status:

```bash
hasura-dev server status
```

Expected output includes:
- `instance=... status=running`
- `endpoint=http://127.0.0.1:8080`
- `postgres_uri=...`

Health check:

```bash
curl -fsS http://127.0.0.1:8080/healthz
```

Expected response:

```text
OK
```

Open console:

- Browser: `http://127.0.0.1:8080/console`
- CLI-served console:

```bash
hasura-dev console --endpoint http://127.0.0.1:8080 --admin-secret <admin-secret>
```

Stop runtime:

```bash
hasura-dev server stop
```

## Existing project quick start (Docker Compose replacement)

From your Hasura project directory:

```bash
cd <project-dir>
hasura-dev server start-dev --detach --apply-project --admin-secret <admin-secret>
```

What `--apply-project` does:
- Runs `deploy` against the local runtime endpoint after startup.
- Applies project metadata and migrations.
- If `--with-seeds` is set, applies seeds too.

Start with seeds:

```bash
hasura-dev server start-dev --detach --apply-project --with-seeds --admin-secret <admin-secret>
```

Day-to-day loop:

1. Start runtime: `hasura-dev server start-dev --detach --apply-project --admin-secret <admin-secret>`
2. Verify: `hasura-dev server status` and `curl -fsS http://127.0.0.1:8080/healthz`
3. Work in console: `http://127.0.0.1:8080/console`
4. Run migrations/metadata commands as needed.
5. Stop: `hasura-dev server stop`

## How the runtime works

### Postgres

- Default mode starts embedded Postgres as a local native process.
- CLI ensures these databases exist:
  - `hasura_metadata`
  - `hasura_default`
- Runtime data lives under:
  - `~/.hasura/dev/<instance>/postgres-data`
  - `~/.hasura/dev/<instance>/postgres-runtime`

### Hasura engine

- Engine runs as a local subprocess (`graphql-engine serve`).
- If `--engine-path` is not provided, engine is downloaded from this repo's release manifest and cached locally.
- Environment wiring includes:
  - `HASURA_GRAPHQL_METADATA_DATABASE_URL`
  - `HASURA_GRAPHQL_DATABASE_URL`
  - `PG_DATABASE_URL` (legacy compatibility)
  - `HASURA_GRAPHQL_ENABLE_CONSOLE=true`
  - `HASURA_GRAPHQL_DEV_MODE=true`

### Hasura console

- Console is served by the engine at `http://<host>:<port>/console`.
- `hasura-dev console` is still available and optional when engine console is enabled.

### State and lifecycle

- Detached mode uses a supervisor process and state files.
- State files live in: `~/.hasura/dev/instances/<instance>.json`.
- `status` and `stop` operate on this instance state.

## Runtime modes

### Embedded Postgres mode (default)

Do not pass `--postgres-uri`.

```bash
hasura-dev server start-dev --detach --admin-secret <admin-secret>
```

### External Postgres mode

Pass an external URL and embedded Postgres is skipped:

```bash
hasura-dev server start-dev --detach \
  --postgres-uri <postgres-uri> \
  --admin-secret <admin-secret>
```

Notes:
- CLI still ensures `hasura_metadata` and `hasura_default` databases exist on that Postgres server.
- Use this when your team already has a shared or pre-existing Postgres instance.

### Attached vs detached

- Attached mode:
  - Omit `--detach`.
  - Runtime stops on `Ctrl+C` or terminal signal.
- Detached mode:
  - Include `--detach`.
  - Runtime persists after terminal closes.
  - Manage with `hasura-dev server status` and `hasura-dev server stop`.

### Ephemeral mode

```bash
hasura-dev server start-dev --detach --ephemeral --admin-secret <admin-secret>
```

When stopped, data directory for that instance is removed.

## Command reference (focused)

### `hasura-dev server start-dev`

High-value flags:
- `--port <port>`: Hasura HTTP port (default `8080`)
- `--host <host>`: bind host (default `127.0.0.1`)
- `--admin-secret <secret>`
- `--instance <name>`: explicit runtime instance name
- `--apply-project`: run `deploy` automatically after startup if project exists
- `--with-seeds`: apply seeds with `--apply-project`
- `--postgres-uri <uri>`: use external Postgres
- `--ephemeral`: delete runtime data on stop
- `--engine-path <path>`: use a local engine binary instead of auto-download

### `hasura-dev server status`

Reports:
- `instance`, `status`
- `endpoint`
- `postgres_uri`
- `supervisor_pid`, `engine_pid`
- `supervisor_alive`, `engine_alive`
- `engine_log` and `started_at` when available

### `hasura-dev server stop`

- Stops detached runtime for the current or specified instance.
- Cleans stale instance state if processes are already gone.

## Day-to-day Hasura workflow mapping

The Docker-free runtime keeps standard Hasura v2 workflows intact.

### Apply project state

Automatic on startup:

```bash
hasura-dev server start-dev --detach --apply-project --admin-secret <admin-secret>
```

Manual:

```bash
hasura-dev deploy --endpoint http://127.0.0.1:8080 --admin-secret <admin-secret>
```

### Create and apply migrations

From project directory:

```bash
hasura-dev migrate create add_new_table --database-name default
hasura-dev migrate apply --database-name default \
  --endpoint http://127.0.0.1:8080 \
  --admin-secret <admin-secret>
```

### Apply metadata

```bash
hasura-dev metadata apply \
  --endpoint http://127.0.0.1:8080 \
  --admin-secret <admin-secret>
```

Optional stricter check:

```bash
hasura-dev metadata apply \
  --disallow-inconsistent-metadata \
  --endpoint http://127.0.0.1:8080 \
  --admin-secret <admin-secret>
```

### Apply seeds

```bash
hasura-dev seed apply \
  --endpoint http://127.0.0.1:8080 \
  --admin-secret <admin-secret>
```

### Console

- Engine-hosted console: `http://127.0.0.1:8080/console`
- CLI console command:

```bash
hasura-dev console --endpoint http://127.0.0.1:8080 --admin-secret <admin-secret>
```

## One-command team workflow template

Use this if you want a single command to start local runtime, apply project, and print health/status.

### `.env`

```bash
HASURA_BIN=hasura-dev
HASURA_PROJECT_DIR=<project-dir>
HASURA_PORT=8080
HASURA_ADMIN_SECRET=<admin-secret>
HASURA_INSTANCE=
HASURA_WITH_SEEDS=true
HASURA_EPHEMERAL=false

# Add any env vars your metadata/actions/events require, for example:
WEB_APP_URL=http://localhost:3000
WEBAPP_HANDLER_SECRET=dev-secret
```

### `run.sh`

```bash
#!/usr/bin/env bash
set -euo pipefail

set -a
source ./.env
set +a

INSTANCE_ARGS=()
if [[ -n "${HASURA_INSTANCE:-}" ]]; then
  INSTANCE_ARGS+=(--instance "${HASURA_INSTANCE}")
fi

cd "${HASURA_PROJECT_DIR}"

if "${HASURA_BIN}" server status "${INSTANCE_ARGS[@]}" 2>/dev/null | grep -q "status=running"; then
  echo "Instance is already running"
else
  CMD=(
    "${HASURA_BIN}" server start-dev
    --detach
    --port "${HASURA_PORT}"
    --admin-secret "${HASURA_ADMIN_SECRET}"
    --apply-project
  )
  if [[ "${HASURA_WITH_SEEDS:-true}" == "true" ]]; then
    CMD+=(--with-seeds)
  fi
  if [[ "${HASURA_EPHEMERAL:-false}" == "true" ]]; then
    CMD+=(--ephemeral)
  fi
  if (( ${#INSTANCE_ARGS[@]} )); then
    CMD+=("${INSTANCE_ARGS[@]}")
  fi
  "${CMD[@]}"
fi

echo
"${HASURA_BIN}" server status "${INSTANCE_ARGS[@]}"
echo
curl -fsS "http://127.0.0.1:${HASURA_PORT}/healthz"
echo
echo "Console: http://127.0.0.1:${HASURA_PORT}/console"
```

### `stop.sh`

```bash
#!/usr/bin/env bash
set -euo pipefail

set -a
source ./.env
set +a

INSTANCE_ARGS=()
if [[ -n "${HASURA_INSTANCE:-}" ]]; then
  INSTANCE_ARGS+=(--instance "${HASURA_INSTANCE}")
fi

cd "${HASURA_PROJECT_DIR}"
"${HASURA_BIN}" server stop "${INSTANCE_ARGS[@]}"
```

## Migrating from Docker Compose

| Docker Compose model | hasura-dev model |
| --- | --- |
| Postgres container | Embedded Postgres process (default) |
| Hasura container | Local `graphql-engine` subprocess |
| `docker compose up` | `hasura-dev server start-dev --detach ...` |
| `docker compose down` | `hasura-dev server stop` |
| Docker volume lifecycle | Local runtime dirs under `~/.hasura/dev/<instance>` |
| Container logs | Supervisor and engine log files |

What changes:
- No Docker daemon dependency for local Hasura runtime.
- No Docker bridge networking/container names to manage.

What stays the same:
- Hasura project structure.
- Migrations/metadata/seeds lifecycle.
- Console and GraphQL development flow.

## Troubleshooting

### Engine download or manifest errors

- Confirm connectivity to GitHub releases for this repo.
- Verify you are on `v0.1.3+`.
- Fallback: pass `--engine-path <local-graphql-engine-binary>`.

### Port already in use

- Change `--port` for Hasura.
- Optionally set `--pg-port` if you need a fixed embedded Postgres port.

### Metadata inconsistency after startup

- Ensure required environment variables (actions/event triggers/etc.) are set in shell or `.env`.
- Re-run `hasura-dev deploy --endpoint ... --admin-secret ...`.

### Stale status entry

If processes were killed externally, `hasura-dev server status` and `hasura-dev server stop` will clean stale state for that instance.

### Log locations

- Supervisor log: `~/.hasura/dev/<instance>/logs/supervisor.log`
- Engine log: `~/.hasura/dev/<instance>/logs/engine.log`

### Useful diagnostics

```bash
hasura-dev version
hasura-dev server status --instance <instance>
curl -fsS http://127.0.0.1:<port>/healthz
```

## Learn more (official Hasura docs)

- Hasura v2 docs index: https://hasura.io/docs/2.0/index/
- Hasura CLI overview: https://hasura.io/docs/2.0/hasura-cli/overview/
- Hasura CLI command reference root: https://hasura.io/docs/2.0/hasura-cli/commands/hasura/
- Migrations, metadata, seeds overview: https://hasura.io/docs/2.0/migrations-metadata-seeds/overview/
- Manage migrations: https://hasura.io/docs/2.0/migrations-metadata-seeds/manage-migrations/
- Manage metadata: https://hasura.io/docs/2.0/migrations-metadata-seeds/manage-metadata/
- Console command docs: https://hasura.io/docs/2.0/hasura-cli/commands/hasura_console/

This README covers the Docker-free local runtime workflow gap. Core Hasura feature semantics remain defined by the official Hasura v2 documentation.

## Distribution notes

This repository is the single public distribution source for:
- CLI binaries (`hasura-dev-*` tarballs)
- Engine release assets (`manifest.json`, `graphql-engine-*`, `checksums.txt`)
- Homebrew formula (`Formula/hasura-dev.rb`)

Release model:
- CLI tags: `v0.1.x`
- Engine tags: `v2.xx.xx`

Default engine manifest URL used by distributed binaries:
- `https://github.com/faisalil/hasura-dev-cli/releases/download/%s/manifest.json`

Implementation source of truth for CLI runtime code changes:
- https://github.com/faisalil/hasura-dev-graphql-engine-private
