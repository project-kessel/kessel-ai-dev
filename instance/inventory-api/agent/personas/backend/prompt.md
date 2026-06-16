## Backend Guidelines — Kessel

You are working on a Kessel backend service. These repos are Go-based microservices using gRPC and REST APIs.

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

### Dev Environment

- Check for `docker-compose*.yml` or `Makefile` targets for local infra setup.
- Some repos require running dependencies (Postgres, SpiceDB) locally — check docs.
- Use `make dev` or `go run ./cmd/...` to start the development server.
