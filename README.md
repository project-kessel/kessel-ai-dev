# kessel-ai-dev

Custom bot runner for the Kessel team, built on [dev-bot](https://github.com/RedHatInsights/platform-frontend-ai-dev) (platform-frontend-ai-dev).

This repo contains instance-specific configuration only — the bot code lives in the `dev-bot` submodule.

## Structure

```
├── setup.sh                          # Instance setup (runs during Docker build)
├── deploy/
│   └── template.yaml                 # OpenShift deploy template (bot-only)
├── instance/
│   └── inventory-api/
│       └── agent/
│           ├── mcp.json              # MCP server config (Jira)
│           ├── project-repos.json    # Repos this instance works on
│           └── personas/
│               └── backend/
│                   └── prompt.md     # Backend coding guidelines
└── dev-bot/                          # Submodule → platform-frontend-ai-dev
```

## Jira labels and repos

The bot picks up tickets that have **two kinds of labels**:

1. **Primary label** — set via `BOT_LABEL` in `deploy/template.yaml`. Marks tickets as eligible for this deployment.
2. **`repo:<name>`** — on the Jira ticket. Tells the bot which repo(s) to clone. Must match a key in the instance's `project-repos.json`.

| Jira primary label | Instance config | `repo:` label | Upstream repo |
|--------------------|-----------------|---------------|---------------|
| `hcc-ai-kessel` | `instance/inventory-api/agent/` | `repo:inventory-api` | [project-kessel/inventory-api](https://github.com/project-kessel/inventory-api) |

To add a repo:

1. Fork it under the bot account and add an entry to the instance's `project-repos.json`:

   ```json
   "my-repo": {
     "url": "https://github.com/platex-rehor-bot/my-repo",
     "upstream": "https://github.com/project-kessel/my-repo.git"
   }
   ```

2. Label the Jira ticket with `repo:my-repo` (bare name) or `repo:project-kessel/my-repo` (org-prefixed — resolved via the upstream URL).

3. Rebuild and redeploy the image so the updated `project-repos.json` is baked in.

Multiple `repo:` labels on one ticket are supported for cross-repo work. A ticket without a matching `repo:` label is skipped.

## Build

```bash
git submodule update --init --recursive
docker build -f dev-bot/Dockerfile.runner -t kessel-ai-dev:local .
```

## Updating dev-bot

```bash
cd dev-bot && git pull origin master && cd ..
git add dev-bot
git commit -m "chore: update dev-bot submodule"
```

## CI/CD

Built and deployed via [Konflux](https://konflux-ci.dev/). Pipeline definitions live in `.tekton/`.

- **Push to main** → builds and pushes to the production Quay repo
- **Pull requests** → builds a temporary image to `quay.io/redhat-user-workloads/...` (5-day expiry)

## Deployment

Deployed to the shared `platform-frontend-ai-dev` namespace via app-interface. Uses the shared proxy, memory server, and Vault secrets from the primary instance. See the deploy template for resource configuration.

See [dev-bot/docs/ONBOARDING.md](dev-bot/docs/ONBOARDING.md) for full onboarding steps.

