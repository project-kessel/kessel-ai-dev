# fabric-kessel-ai-dev

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

## Build

```bash
git submodule update --init --recursive
docker build -f dev-bot/Dockerfile.runner -t fabric-kessel-ai-dev:local .
```

## Updating dev-bot

```bash
cd dev-bot && git pull origin master && cd ..
git add dev-bot
git commit -m "chore: update dev-bot submodule"
```

## Deployment

Deployed to the shared `platform-frontend-ai-dev` namespace via app-interface. Uses the shared proxy, memory server, and Vault secrets from the primary instance.

See [dev-bot/docs/ONBOARDING.md](dev-bot/docs/ONBOARDING.md) for full onboarding steps.
