#!/bin/bash
# Idempotent inventory-api environment setup — run before working on inventory-api.
# Usage: setup-inventory-env.sh [path/to/inventory-api]
#
# Handles: postgres/inventory-api sidecar health checks, Go deps, build verification.
# Ends with a validation summary so failures are immediately visible in output.
# Safe to run multiple times (skips steps already done).

set -euo pipefail

REPO_DIR="$(cd "${1:-.}" && pwd)"
cd "$REPO_DIR"

PASS=0; WARN=0; FAIL=0

ok()   { echo "  [OK] $*"; PASS=$((PASS+1)); }
warn() { echo "  [WARN] $*"; WARN=$((WARN+1)); }
fail() { echo "  [FAIL] $*"; FAIL=$((FAIL+1)); }

# ─── 1. Wait for PostgreSQL sidecar (up to 60s) ──────────────────────────────

echo ""
echo "[inventory-setup] Waiting for PostgreSQL sidecar at localhost:5433..."
PG_READY=false
for i in $(seq 1 30); do
  if (echo > /dev/tcp/localhost/5433) 2>/dev/null; then
    PG_READY=true
    break
  fi
  sleep 2
done

if [ "$PG_READY" = "false" ]; then
  echo "[inventory-setup] ERROR: PostgreSQL sidecar not ready after 60s. Aborting." >&2
  exit 1
fi

# ─── 2. Wait for inventory-api sidecar (up to 90s — migration may take time) ─

echo "[inventory-setup] Waiting for inventory-api at localhost:8081..."
INV_READY=false
for i in $(seq 1 45); do
  if curl -sf http://localhost:8081/api/kessel/v1/livez >/dev/null 2>&1; then
    INV_READY=true
    break
  fi
  sleep 2
done

if [ "$INV_READY" = "false" ]; then
  warn "inventory-api sidecar not responding at localhost:8081 — e2e tests unavailable"
fi

# ─── 3. Check Go version ─────────────────────────────────────────────────────

echo "[inventory-setup] Checking Go toolchain..."
GO_VER=$(go version 2>/dev/null | awk '{print $3}' | sed 's/go//' || echo "unknown")
REQUIRED_VER=$(grep '^go ' go.mod 2>/dev/null | awk '{print $2}' || echo "unknown")

if [ "$GO_VER" != "unknown" ]; then
  GO_MAJOR_MINOR=$(echo "$GO_VER" | cut -d. -f1,2)
  REQ_MAJOR_MINOR=$(echo "$REQUIRED_VER" | cut -d. -f1,2)
  if [ "$GO_MAJOR_MINOR" = "$REQ_MAJOR_MINOR" ]; then
    ok "Go $GO_VER (go.mod requires $REQUIRED_VER)"
  else
    warn "Go $GO_VER installed, go.mod requires $REQUIRED_VER — try: eval \"\$(use-go $REQUIRED_VER)\""
  fi
else
  fail "Go not found on PATH"
fi

# ─── 4. Download Go dependencies ─────────────────────────────────────────────

echo "[inventory-setup] Downloading Go dependencies..."
if go mod download 2>&1; then
  ok "go mod download"
else
  fail "go mod download failed"
fi

# ─── 5. Validation summary ───────────────────────────────────────────────────

echo ""
echo "┌─────────────────────────────────────────────────────────────┐"
echo "│  Inventory API Environment Validation                       │"
echo "└─────────────────────────────────────────────────────────────┘"

if [ "$PG_READY" = "true" ]; then
  ok "PostgreSQL localhost:5433"
else
  fail "PostgreSQL localhost:5433 not reachable"
fi

if [ "$INV_READY" = "true" ]; then
  ok "Inventory API localhost:8081 (livez OK)"
else
  warn "Inventory API localhost:8081 not responding (e2e tests will be skipped)"
fi

echo "[inventory-setup] Verifying build..."
if make local-build >/dev/null 2>&1; then
  ok "make local-build"
else
  fail "make local-build failed"
fi

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
