## Frontend SDK Guidelines — Kessel

You are working on a Kessel browser or Node.js TypeScript SDK.

**Also read `personas/sdk/prompt.md`** — it contains cross-language SDK rules, generated-code boundaries, and language-specific test/lint commands.

### General

- Follow existing patterns in the codebase.
- Read `AGENTS.md` / `CLAUDE.md` and the relevant `docs/*-guidelines.md` files.
- `npm install` first — if it fails, stop and report on Jira.
- **npm scripts only** — never call `npx jest`, `npx eslint`, or `npx tsc` directly.
- Run tests and lint before committing.
- Never edit generated protobuf/gRPC TypeScript stubs.

### Node SDK (`kessel-sdk-node`)

- Node >= 20. Package: `@project-kessel/kessel-sdk`.
- `npm test` — Jest unit tests
- `npm run lint:check` — ESLint
- `npm run type-check` — TypeScript
- `npm run build` — verify CJS/ESM/types build
- Hand-written code in `src/kessel/auth/`, `src/kessel/grpc/`, `src/kessel/inventory/index.ts`, `src/kessel/rbac/`, `src/promisify.ts`.
- Examples in `examples/` require a live server — not CI tests.

### Browser SDK (`kessel-sdk-browser`)

- NX monorepo. Check `.nvmrc` for Node version.
- `npm test`, `npm run lint`, `npm run build` before commit.
- Primary package: `@project-kessel/react-kessel-access-check`.
- React Provider/Context pattern for access checks; respect hook overloads for single vs bulk checks.
- Write component tests following existing patterns in the package.
- No HCC dev proxy or SSO login required for SDK-only changes — unit tests and package build are sufficient verification.
