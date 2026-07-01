## Backend SDK Guidelines — Kessel

You are working on a Kessel SDK with a compiled backend language (Go, Python, Java, or Ruby).

**Also read `personas/sdk/prompt.md`** — it contains cross-language SDK rules, generated-code boundaries, and language-specific test/lint commands.

### General

- Follow existing patterns in the codebase.
- Read `AGENTS.md` / `CLAUDE.md` and the relevant `docs/*-guidelines.md` files.
- Run the repo's test and lint commands before committing.
- Never edit generated protobuf/gRPC files.

### Go SDK (`kessel-sdk-go`)

- Check `go.mod` for Go version; use `eval "$(use-go <version>)"` if the default differs.
- `make test`, `make lint`, `make fmt` before commit.
- Table-driven tests. Explicit error handling — no silent `_` on errors.
- New logic goes in hand-written packages under `kessel/auth/`, `kessel/grpc/`, `kessel/inventory/internal/builder/`, `kessel/rbac/`.

### Python SDK (`kessel-sdk-py`)

- `pytest` for tests; `black --check .` and `flake8` for lint.
- Async tests use `pytest-asyncio`.
- Hand-written code under `src/kessel/auth/`, `src/kessel/grpc/`, `src/kessel/inventory/`, `src/kessel/rbac/`.

### Java SDK (`kessel-sdk-java`)

- `./mvnw clean verify` before commit.
- Multi-module: SDK artifact in `kessel-sdk/`, examples separate.
- Hand-written code in `org.project_kessel.api.auth`, `grpc`, `inventory`, `rbac`.

### Ruby SDK (`kessel-sdk-ruby`)

- `bundle exec rspec` and `bundle exec rubocop` before commit.
- Update RBS signatures in `sig/` when changing public APIs.
- Target `V1beta2` for new features unless working with legacy services.
