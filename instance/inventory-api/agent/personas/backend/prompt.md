## Backend Guidelines — Kessel

You are working on a Kessel backend service. These repos are Go-based microservices using gRPC and REST APIs.

### Before changes

Run the setup script — it handles everything (sidecar health check, Go deps, build verification) and is safe to re-run:

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
- Use `make test` to run unit tests.
- Use `make local-build` to verify the project compiles (NOT `make build` — that requires FIPS and fails locally).
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

Run these commands in order before committing:

```bash
set -ex

echo "BUILD CHECK"
make local-build

echo "UNIT TESTS"
make test

echo "LINTING"
go vet ./...
gofmt -l .
```

If the inventory-api sidecar is healthy (setup script confirms it), also run the HTTP e2e smoke test:

```bash
echo "E2E SMOKE TEST"
go test ./test/e2e/... -count=1 -v -run 'TestInventoryAPIHTTP_Livez'
```

Do NOT run `make inventory-up-kind`, `docker-compose`, or any Docker-based test commands.
There is no Docker daemon in this environment.

### Dev Environment

PostgreSQL and inventory-api are pre-provisioned as pod sidecars:

- **PostgreSQL**: `localhost:5433` (user: `postgres`, password: `yPsw5e6ab4bvAGe5H`, database: `spicedb`)
- **Inventory API**: `localhost:8081` (HTTP), `localhost:9081` (gRPC) — configured with `authz: allow-all`

`make start-db`, `docker-compose`, and `make inventory-up-kind` are NOT available (no Docker daemon).

### Escalation

- If the same test fails **3 times** with different attempted fixes → **STOP**. Post the full error output to Jira and ask for human help.
- Do **not** poll `gh pr checks` in a loop to watch CI. CI is a final gate only — run tests locally first.
- If you keep hitting infrastructure issues (sidecar not responding, out of disk, etc.) → **STOP** and report to Jira.

### What NOT to Do

- Do not run `make inventory-up-kind` or any Docker/Kind commands — there is no container runtime.
- Do not skip tests before committing.
- Do not push code that does not compile (`make local-build` must pass).
- Do not wait for GitHub CI checks to find bugs you could catch locally.
