#!/bin/bash
# Idempotent inventory-api environment setup — run before working on inventory-api.
# Usage: setup-inventory-env.sh [path/to/inventory-api]
#
# Handles: postgres sidecar health check, Go toolchain verification, make pr-check,
# and migration smoke test. Ends with a validation summary.
# Safe to run multiple times (skips steps already done).

set -euo pipefail

REPO_DIR="$(cd "${1:-.}" && pwd)"
cd "$REPO_DIR"

# ─── helpers ──────────────────────────────────────────────────────────────────

PASS=0; WARN=0; FAIL=0

ok()   { echo "  [OK]   $*"; PASS=$((PASS+1)); }
warn() { echo "  [WARN] $*"; WARN=$((WARN+1)); }
fail() { echo "  [FAIL] $*"; FAIL=$((FAIL+1)); }

PG_HOST="${POSTGRES_HOST:-localhost}"
PG_PORT="${POSTGRES_PORT:-15432}"
PG_DB="${POSTGRES_DB:-inventory}"
PG_USER="${POSTGRES_USER:-inventory}"
PG_PASS="${POSTGRES_PASSWORD:-inventory_password}"

# ─── 1. Wait for postgres sidecar (up to 60s) ─────────────────────────────────

echo ""
echo "[inventory-setup] Waiting for PostgreSQL sidecar at ${PG_HOST}:${PG_PORT}..."
for i in $(seq 1 30); do
    if python3 -c "import socket; s=socket.create_connection(('${PG_HOST}',${PG_PORT}),1); s.close()" 2>/dev/null; then
        break
    fi
    if [ "$i" -eq 30 ]; then
        echo "[inventory-setup] ERROR: PostgreSQL sidecar not ready after 60s. Aborting." >&2
        exit 1
    fi
    sleep 2
done

# ─── 2. Verify Go toolchain ───────────────────────────────────────────────────

echo "[inventory-setup] Checking Go toolchain..."
REQUIRED_GO=$(grep '^go ' go.mod 2>/dev/null | awk '{print $2}' || echo "unknown")
CURRENT_GO=$(go version 2>/dev/null | grep -oE 'go[0-9]+\.[0-9]+(\.[0-9]+)?' | head -1 || echo "none")

if [ "$CURRENT_GO" = "none" ]; then
    echo "[inventory-setup] ERROR: Go not found. Aborting." >&2
    exit 1
fi

# Switch Go version if needed and use-go is available
if [ -f /usr/local/bin/use-go ] && [ "$REQUIRED_GO" != "unknown" ]; then
    if ! go version 2>/dev/null | grep -q "go${REQUIRED_GO}"; then
        echo "[inventory-setup] Switching to Go ${REQUIRED_GO}..."
        eval "$(use-go "${REQUIRED_GO}")" 2>/dev/null || true
    fi
fi

# ─── 3. Download dependencies ────────────────────────────────────────────────

echo "[inventory-setup] Downloading Go dependencies..."
go mod download

# ─── 4. Run make pr-check (unit tests + lint + build) ─────────────────────────

echo "[inventory-setup] Running make pr-check (generate + test + lint + build)..."
if ! make pr-check; then
    echo "[inventory-setup] ERROR: make pr-check failed. Aborting." >&2
    exit 1
fi

# ─── 5. Run migration smoke test ──────────────────────────────────────────────

echo "[inventory-setup] Running migration smoke test..."
if ! go run main.go migrate \
    --storage.database=postgres \
    --storage.postgres.host="${PG_HOST}" \
    --storage.postgres.port="${PG_PORT}" \
    --storage.postgres.dbname="${PG_DB}" \
    --storage.postgres.user="${PG_USER}" \
    --storage.postgres.password="${PG_PASS}" \
    --storage.postgres.sslmode=disable; then
    echo "[inventory-setup] ERROR: Migration smoke test failed. Aborting." >&2
    exit 1
fi

# ─── 6. Validation summary ────────────────────────────────────────────────────

echo ""
echo "┌─────────────────────────────────────────────────────────────┐"
echo "│            Inventory API Environment Validation             │"
echo "└─────────────────────────────────────────────────────────────┘"

# Go version
GO_VER=$(go version 2>/dev/null | grep -oE 'go[0-9]+\.[0-9]+(\.[0-9]+)?' | head -1 || echo "unknown")
if [ "$GO_VER" != "none" ] && [ "$GO_VER" != "unknown" ]; then
    ok "Go $GO_VER"
else
    fail "Go not found"
fi

# PostgreSQL connectivity
PG_VER=$(PGPASSWORD="${PG_PASS}" psql -h "${PG_HOST}" -p "${PG_PORT}" -U "${PG_USER}" -d "${PG_DB}" \
    -tAc "SELECT version();" 2>/dev/null | head -1 || true)
if [[ "$PG_VER" == *PostgreSQL* ]]; then
    PG_SHORT=$(echo "$PG_VER" | grep -oE 'PostgreSQL [0-9]+\.[0-9]+')
    ok "PostgreSQL $PG_SHORT (${PG_HOST}:${PG_PORT})"
else
    # psql might not be available — fall back to socket check
    if python3 -c "import socket; s=socket.create_connection(('${PG_HOST}',${PG_PORT}),1); s.close()" 2>/dev/null; then
        ok "PostgreSQL ${PG_HOST}:${PG_PORT} (reachable, psql not available for version check)"
    else
        fail "PostgreSQL cannot connect to ${PG_HOST}:${PG_PORT}"
    fi
fi

# Build artifact
if [ -f bin/inventory-api ]; then
    ok "Binary bin/inventory-api built"
else
    warn "Binary bin/inventory-api not found (make local-build may use different path)"
fi

# Migration
ok "Migration smoke test passed"

# pr-check
ok "make pr-check passed"

# ─── Result ───────────────────────────────────────────────────────────────────

echo ""
echo "  Passed: $PASS  Warnings: $WARN  Failed: $FAIL"
echo ""

if [ "$FAIL" -gt 0 ]; then
    echo "[inventory-setup] FAILED — fix the items above before proceeding." >&2
    exit 1
fi

if [ "$WARN" -gt 0 ]; then
    echo "[inventory-setup] Ready (with warnings)."
else
    echo "[inventory-setup] All checks passed. Inventory API environment ready."
fi
