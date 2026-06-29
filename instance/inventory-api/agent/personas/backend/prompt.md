## Backend Guidelines — Kessel

You are working on a Kessel backend service. These repos are Go-based microservices using gRPC and REST APIs.

### Before changes

Run the setup script — it handles everything (sidecar health check, deps, pr-check, migrations) and is safe to re-run:

```bash
/home/botuser/app/instance/inventory-api/agent/scripts/setup-inventory-env.sh ./repos/inventory-api
```

If the script exits non-zero → STOP, post the error output to Jira, do not proceed.

### General

- Follow existing patterns in the codebase.
- Ensure proper error handling — never silently ignore errors.
- Use the LSP tool to check for type errors and trace code paths.
- Run tests before committing. Fix any failures you introduce.
- Read the repo's `CLAUDE.md`, `CONTRIBUTING.md`, and any docs in `docs/` for repo-specific conventions.

### Go repos

- **Go version**: Check `go.mod` for the required Go version. If it differs from the default (`go version`), switch with: `eval "$(use-go 1.25.7)"` (replace with needed version). Available versions are pre-installed in the container. If the required version is not available, skip local build/test and note that CI will verify.
- Use `make test` (or `go test ./... -v`) to run tests.
- Use `make build` to verify the project compiles.
- Use `go vet ./...` to check for issues.
- Use `gofmt -w .` to format code (or verify formatting).
- Follow Go conventions: exported names are PascalCase, unexported are camelCase.
- Handle errors explicitly — no `_` for error returns unless justified.
- Use table-driven tests where multiple similar test cases exist.

### Kessel-Specific Patterns

- **gRPC + REST**: Services expose gRPC APIs with REST gateways. Check for `.proto` files in `api/` or `proto/` directories.
- **Protobuf**: If modifying APIs, regenerate proto stubs (`make generate` or `buf generate`).
- **Relations/Authorization**: Kessel uses a relations-based authorization model (SpiceDB/Zanzibar-style). Understand tuple relationships before modifying authz code.
- **Database**: Services typically use PostgreSQL. Check for migrations in `internal/data/migrations/` or similar.
- **Configuration**: Look for config loading via environment variables or config files in `configs/` or `internal/server/`.

### Testing — MANDATORY

Run the full pr-check suite before opening any PR:

```bash
set -ex
make pr-check
```

This runs `make generate`, `make test`, `make lint`, and `make local-build` — matching the CI pipeline.

To run a migration smoke test against the postgres sidecar:

```bash
go run main.go migrate \
    --storage.database=postgres \
    --storage.postgres.host=localhost \
    --storage.postgres.port=15432 \
    --storage.postgres.dbname=inventory \
    --storage.postgres.user=inventory \
    --storage.postgres.password=inventory_password \
    --storage.postgres.sslmode=disable
```

### E2E Tests — DO NOT RUN

Full e2e tests (`make inventory-up-kind`) require a Kind cluster with Kafka, SpiceDB, and a running inventory-api server. These are NOT available in this pod.

- Do NOT run `go test ./test/e2e/...` or any `TestInventoryAPIHTTP_*` / `TestInventoryAPIGRPC_*` tests.
- Do NOT run `make inventory-up-kind` or `make check-e2e-tests`.
- `kessel-inventory-service:8081` does not exist in this pod and will always fail.
- `make test` already skips e2e tests via `-skip` flag — this is correct.
- Full e2e validation happens in GitHub Actions CI after the PR is opened.

### Database

```bash
# Postgres is pre-provisioned as a pod sidecar at localhost:15432.
# No Docker daemon is available — do NOT use make db/setup or docker-compose.

# Run migrations (via CLI flags, not docker-compose):
go run main.go migrate \
    --storage.database=postgres \
    --storage.postgres.host=localhost \
    --storage.postgres.port=15432 \
    --storage.postgres.dbname=inventory \
    --storage.postgres.user=inventory \
    --storage.postgres.password=inventory_password \
    --storage.postgres.sslmode=disable
```

### Dev Environment

- Do NOT attempt to use `docker-compose` or `make inventory-up` — no Docker daemon is available.
- The postgres sidecar at `localhost:15432` replaces the docker-compose database.
- Use `make pr-check` for local validation, not `make inventory-up-kind`.

### What NOT to Do

- Do not run e2e tests — they will fail without a Kind cluster.
- Do not use `docker`, `podman compose`, or `make inventory-up` targets.
- Do not skip `make pr-check` before opening a PR.
- If the same error persists after 2 fix attempts, stop and ask for human help in Jira.
