## Kessel SDK Guidelines

You are working on a **Project Kessel SDK** repository. Load this persona for every `kessel-sdk-*` repo regardless of language.

These SDKs are client libraries for the Kessel Inventory and RBAC APIs. They share the same architectural patterns across languages.

### General

- Follow existing patterns in the codebase.
- Read the repo's `CLAUDE.md` / `AGENTS.md` first — it references domain-specific docs in `docs/`.
- Read relevant `docs/*-guidelines.md` before changing auth, errors, API contracts, testing, performance, or integration code.
- Ensure proper error handling — never silently ignore errors.
- Use the LSP tool to check for type errors and trace code paths.
- Run tests and lint before committing. Fix any failures you introduce.
- Never skip pre-commit hooks with `--no-verify` unless explicitly requested.

### Generated vs Hand-Written Code — Critical

**Never edit generated protobuf/gRPC files.** They are regenerated from `buf.build/project-kessel/inventory-api` via `buf generate` / `make generate`. A scheduled CI workflow opens PRs when upstream protos change.

Generated file patterns (do not edit):
- Go: `*.pb.go`, `*_grpc.pb.go`
- Python: `*_pb2.py`, `*_pb2_grpc.py`
- Java: files with `@Generated` / `@GrpcGenerated` annotations
- Ruby: `*_pb.rb`, `*_services_pb.rb`
- Node/TS: generated `.ts` stubs under `src/kessel/inventory/v*/` (except hand-written `index.ts`)
- Browser: generated types if present under package build output

**Hand-written code** is where all new logic goes: auth, grpc credentials, `ClientBuilder`, RBAC helpers, examples, and tests.

When modifying APIs, changes belong in the upstream inventory-api proto repo — not by editing generated stubs.

### Cross-Language Architecture

- **Current API version**: `v1beta2` (unified inventory service). Prefer v1beta2 unless explicitly working with legacy code.
- **ClientBuilder pattern**: Fluent builder for constructing authenticated gRPC clients. Follow existing builder usage in each repo.
- **Auth**: OAuth2 Client Credentials via OIDC discovery. Optional dependencies for OAuth in some SDKs (Java Nimbus, Node `oauth4webapi`).
- **RBAC helpers**: REST workspace utilities in `rbac/v2` (or equivalent) — hand-written convenience layer on top of gRPC.
- **Examples**: Runnable examples in `examples/` — not automated tests. Do not conflate with test suites.

### Language-Specific Commands

Always prefer `make` targets or npm scripts defined in the repo over calling tools directly.

#### Go (`kessel-sdk-go`)

- Check `go.mod` for Go version; switch with `eval "$(use-go <version>)"` if needed.
- `make test` — run tests (`go test -v ./kessel/...`)
- `make lint` — golangci-lint (via Docker/Podman)
- `make fmt` / `make mod-tidy` — formatting and module hygiene
- `make build` — compile example binaries
- CI requires both lint and test workflows to pass.

#### Python (`kessel-sdk-py`)

- Python 3.11+ (`pyproject.toml`)
- `pytest` — run tests
- `black --check .` and `flake8` — lint (CI runs both)
- `python -m build` — verify package builds
- Use `pytest-asyncio` patterns for async tests.

#### Java (`kessel-sdk-java`)

- Java/Maven multi-module project (`kessel-sdk` + `examples`)
- `./mvnw clean verify` — build, test, and validate (single pre-PR command)
- Never hand-edit generated stubs under `src/main/java` from buf
- Examples module is not published — changes there don't affect the SDK artifact.

#### Ruby (`kessel-sdk-ruby`)

- `bundle install` — install dependencies
- `bundle exec rspec` — run tests (`COVERAGE=1` for coverage)
- `bundle exec rubocop` — lint
- `bundle exec bundler-audit` — security audit
- Maintain RBS type signatures in `sig/` when changing public APIs.

#### Node/TypeScript (`kessel-sdk-node`)

- Node >= 20. Published as `@project-kessel/kessel-sdk`.
- `npm install` before any other commands.
- `npm test` — Jest tests
- `npm run lint:check` — ESLint (use `npm run lint` to auto-fix)
- `npm run type-check` — TypeScript validation
- `npm run build` — CJS + ESM + type declarations
- `npm run prettier:check` — formatting
- Never call `npx jest` / `npx eslint` / `npx tsc` directly — use npm scripts.

#### Browser/React (`kessel-sdk-browser`)

- NX monorepo. Node version in `.nvmrc`.
- `npm install` before any other commands.
- `npm test` — run tests
- `npm run lint` — ESLint
- `npm run build` — build all packages
- Primary package: `@project-kessel/react-kessel-access-check` (React hooks for access checks).
- Uses Provider/Context pattern — follow existing hook overloads and test patterns.
- Visual verification: build and test locally; no HCC dev proxy required unless integrating with a host app.

### Dev Environment

- Check `examples/` for integration patterns requiring a live Kessel server.
- Most unit tests mock gRPC/HTTP — they should run without external services.
- `.env.sample` or docs may describe required env vars for authenticated examples.
