## Parsec Guidelines — Kessel

You are working on **parsec**, a generic OAuth 2.0 token exchange and Envoy
ext_authz service. Parsec is not specific to any single IdP, deployment,
vendor, or organization. Implement tickets following parsec conventions and
produce a clean, mergeable PR.

### Escalate when

**STOP and ask a human** whenever any of these apply:

- Server Go changes that are **not clearly generic** (any IdP, vendor, deployment)
- Specific claim names, issuer URLs, or vendor behaviors hard-coded into Go
- A **new abstraction or policy layer** is needed (design review / multi-PR)
- The ticket touches **gRPC/protobuf API definitions**
- Ambiguous or missing acceptance criteria
- Changes to **credential extraction or trust store routing**
- Security implications beyond standard input validation
- Anything unclear — when in doubt, stop and ask

### Prefer configuration over server code

Parsec has rich configurability (CEL claim mappers, claim filters,
pre-issuance policy, validator filters, trust stores). Prefer those layers
over Go changes. If server code must change, it MUST stay generic. Otherwise
move it to config/policy, generalize it, or escalate.

### Before coding

1. Read the ticket and acceptance criteria. Escalate if ambiguous.
2. Run the config-vs-code gate above. Escalate if it fails.
3. Read `AGENTS.md` and architecture docs under `docs/` (exclude review notes,
   benchmarks, and `impl-plans/`). Follow those conventions — do not re-derive
   coding, testing, observability, or config rules here.
4. Explore affected packages and existing tests before writing code.

### Pod environment

- **No Docker daemon** — do not run `docker`, `podman`, `make lint`, or
  `make pr-check` (lint uses Docker). CI runs lint separately.
- **No Kubernetes** — do not run integration tests from `test/`, deploy
  manifests, or `kubectl`/`oc` commands.
- **Go version** — read the `go` directive in `go.mod` and switch if needed:
  ```bash
  eval "$(use-go <version>)"
  ```
  Or with goenv:
  ```bash
  goenv install "$(grep '^go ' go.mod | awk '{print $2}')"
  goenv local "$(grep '^go ' go.mod | awk '{print $2}')"
  ```

### Pre-PR validation — MANDATORY

Before writing any code, run the baseline. If any step fails → **STOP**, post
the error to Jira, do not proceed:

```bash
go mod download && make build && make test
```

Re-run `make build` and `make test` before opening the PR. Fix failures you
introduce. If config or deploy files change, note the downstream app-interface
sync requirement in the PR description.

### Memory tags

When storing learnings (`memory_store`) for parsec, use these tags:

`transaction-tokens`, `ext-authz`, `token-exchange`, `trust-pipeline`,
`key-rotation`, `data-sources`, `cel-mapping`, `lua-scripting`,
`observer-pattern`, `grpc-gateway`

### What NOT to do

- Do not hard-code IdP/vendor/deployment-specific logic into server Go code.
- Do not run Docker-dependent or Kubernetes-dependent targets in this pod.
- Do not skip pre-PR validation (`make build` + `make test`).
- If the same error persists after 2 fix attempts, stop and ask for human help
  in Jira.
