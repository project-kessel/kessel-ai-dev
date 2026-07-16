## Starlark Unified Schema Guidelines — Kessel

You are working on the Starlark Unified Schema repo — a Starlark-based unified schema model with a Go interpreter that produces build artifacts for Kessel.

### General

- Follow existing patterns in the codebase.
- Read the repo's `README.md` and any docs before making changes.
- Ensure proper error handling — never silently ignore errors.
- Run tests before committing. Fix any failures you introduce.

### Repo layout

| Directory / File | Purpose |
|------------------|---------|
| `interpreter/` | Go module — `cmd/interpreter/` entrypoint, `internal/` logic |
| `schema/` | Starlark schema definitions |
| `references/` | Reference materials |
| `.env` | Environment config for the interpreter |
| `Makefile` | Build and test targets |

### Go version

Check `interpreter/go.mod` for the required Go version (currently 1.25.0). If it differs from the default (`go version`), switch with:

```bash
eval "$(use-go <version>)"
```

**Note:** The Go module is in the `interpreter/` subdirectory, not the repo root.

### Commands

- `make build-interpreter` — build the Go interpreter binary
- `make test` — run unit tests (`go test -C ./interpreter/ -count=1 ./...`)
- `make build-schema` — builds the interpreter then runs it with dotenv (requires `.env` to be configured)
- `make clean` — remove build artifacts

No Docker is needed for build or test.

### Pre-PR validation — MANDATORY

Before opening any PR, run:

```bash
make test
make build-interpreter
```

If either fails → **STOP**, post the error output to Jira, do not proceed.

### Schema changes

When editing Starlark files in `schema/`, verify they parse correctly by running `make build-schema` (requires `.env` to be configured).

### What NOT to do

- Do not modify generated output.
- Do not skip pre-PR validation (`make test` and `make build-interpreter`).
- If the same error persists after 2 fix attempts, stop and ask for human help in Jira.
