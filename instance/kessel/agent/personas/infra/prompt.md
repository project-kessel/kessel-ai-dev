## Infrastructure Guidelines — Kessel AI Dev Bot

You are working on `kessel-ai-dev` — the AI dev bot runner instance repo. This is an infrastructure, deployment, and bot configuration repository (Shell/YAML/Markdown), not a Go service.

### General

- Follow existing patterns in the codebase.
- Read `README.md` before making changes.
- Be careful editing deployment templates and bot configuration — changes affect production.
- Match existing conventions in YAML, JSON, shell scripts, and Markdown files.

### Repo layout

| Path | Description |
|------|-------------|
| `deploy/template.yaml` | OpenShift template — Deployment, NetworkPolicy, KEDA ScaledObject |
| `instance/kessel/agent/` | Bot config — `CLAUDE.md`, `instance.yaml`, `project-repos.json`, `personas/`, `scripts/` |
| `dev-bot/` | Git submodule for the dev-bot framework — do NOT modify directly |
| `.tekton/` | CI pipeline definitions |
| `setup.sh` | Setup script |
| `.gitmodules` | Submodule configuration |

### Deployment template

`deploy/template.yaml` deploys a bot pod with a PostgreSQL sidecar. Key components:

- **Deployment**: Bot container + postgres sidecar, configured via template parameters
- **NetworkPolicy**: Restricts egress to proxy + memory-server + DNS
- **KEDA ScaledObject**: Cron scaler controls uptime (20.5h active, 3.5h downtime)

The template defines parameters for namespace, image, labels, and config. Be careful editing — changes affect production.

### Bot configuration

- `instance.yaml` — defines the workflow, source, envs, and `claude_md` strategy
- `project-repos.json` — maps repo keys to bot fork URLs and upstream URLs
- `CLAUDE.md` — controls persona routing (repo key → persona mapping)
- `personas/` — per-repo guideline prompts loaded by the bot
- `scripts/` — helper scripts run inside the bot pod

### Scripts

`setup.sh` and any scripts in `instance/kessel/agent/scripts/` run inside the bot pod. Test scripts with `shellcheck` if available.

### Pre-PR validation — MANDATORY

Before opening a PR, validate all changed files:

```bash
# YAML changes — validate syntax
python3 -c "import yaml; yaml.safe_load(open('deploy/template.yaml'))"

# JSON changes — validate syntax
python3 -m json.tool instance/kessel/agent/project-repos.json > /dev/null

# Shell scripts — lint with shellcheck
shellcheck setup.sh instance/kessel/agent/scripts/*.sh 2>/dev/null || true

# Template parameters — review ${PARAM} and ${{PARAM}} references
```

### Submodule

`dev-bot/` is a git submodule. To update it:

```bash
git submodule update --remote dev-bot
git add dev-bot
git commit -m "chore: update dev-bot submodule"
```

Do NOT edit files inside `dev-bot/` directly.

### What NOT to Do

- Do not edit files inside `dev-bot/` submodule directly.
- Do not remove existing `project-repos.json` entries without explicit approval.
- Do not modify KEDA scaler timing without team discussion.
- Do not hard-code secrets — use `secretKeyRef`.
- If the same error persists after 2 fix attempts, stop and ask for human help in Jira.
