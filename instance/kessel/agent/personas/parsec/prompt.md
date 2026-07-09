## Parsec Guidelines — Kessel Trust Architecture

You are working on **parsec**, a Go backend service implementing Envoy ext_authz and OAuth 2.0 Token Exchange (RFC 8693) for the Kessel trust architecture.

For other Kessel repos, do **not** use this persona — see instance CLAUDE.md persona routing.

### General

- Follow existing patterns in the codebase.
- Read the repo's `CLAUDE.md`, `AGENTS.md`, and `ARCHITECTURE.md` for repo-specific conventions.
- Ensure proper error handling — never silently ignore errors.
- Use the LSP tool to check for type errors and trace code paths.
- Run tests before committing. Fix any failures you introduce.

### Go version

Check `go.mod` for the required Go version. If it differs from the default (`go version`), switch with:

```bash
eval "$(use-go <version>)"
```

Replace `<version>` with the version from `go.mod` (currently 1.26.4). Available versions are pre-installed in the container. If the required version is not available, skip local build/test and note that CI will verify.

### Generated vs hand-written code

**Never edit generated proto/gRPC files:**

- `*.pb.go`
- `*_grpc.pb.go`

These are generated via `buf generate`. To regenerate: `make generate`.

**Hand-written code** lives in:

- `internal/` — server, trust, service, issuer, mapper, datasource, lua, cel, claims, request, keymanager, config
- `cmd/` — application entrypoints

### Architecture

- **gRPC server** on `:9090` + **HTTP gateway** on `:8080` via grpc-gateway.
- **ext_authz** — Envoy perimeter authorization filter.
- **Token exchange** — `POST /v1/token` implementing RFC 8693.
- **Interface-driven design** — key interfaces: `trust.Validator`, `trust.Store`, `service.Issuer`, `service.DataSource`, `service.ClaimMapper`.
- **Dual identity model** — subject (end-user) + actor (calling service).
- **Lua-scriptable data sources** with CEL claim mapping.

### Commands

- `make build` — compile the binary.
- `make test` — run unit tests with `-short -race`.
- `make generate` — run `go generate` for proto stubs and other generated code.
- `make lint` — runs linter via Docker. **Do NOT run in the pod** (no Docker daemon).
- `make pr-check` — runs generate + test + lint + build. **Do NOT run in the pod** (lint portion uses Docker).

### Pre-PR validation

Run these before opening any PR:

```bash
make test
make build
```

Do **NOT** run `make lint` or `make pr-check` in the pod — lint uses Docker. CI runs lint separately via GitHub Actions.

### Testing

- Unit tests mock gRPC and should run without external services.
- Uses table-driven tests.
- Requires `GOEXPERIMENT=jsonv2` (already set in Makefile).
- Use `make test` (or `go test ./... -short -race`) to validate.

### Dev environment

- **No Docker daemon** is available in this pod.
- Do not run `docker-build-push` or container builds.
- Do not run integration or e2e tests that require external services.

### What NOT to do

- Do not edit generated proto files (`*.pb.go`, `*_grpc.pb.go`).
- Do not run `docker`, `podman`, or container-dependent Makefile targets.
- Do not run `make lint` or `make pr-check` — they use Docker.
- If the same error persists after 2 fix attempts, stop and ask for human help in Jira.
