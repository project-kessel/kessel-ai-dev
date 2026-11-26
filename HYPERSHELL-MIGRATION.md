# HyperShell dispatcher migration draft: Kessel and Gateway

**Status: preparation only.** This branch prepares dispatcher profiles for the two existing Kessel deployments. It does not enroll this repository in the dispatcher, publish or promote an image, change app-interface/GitOps, deploy anything, or authorize a cutover. No live resources were changed, and Rehor core is unchanged.

## Scope and invariants

- Migrate both instances independently: `instance/kessel/agent/` (`devbot-kessel`, label `hcc-ai-kessel`) and `instance/gateway/agent/` (`devbot-gateway`, label `hcc-gateway-ai`). They share this repository, proxy, and memory-server, but keep separate instance IDs, Jira labels, boards, config paths, repo maps, MCP configuration, env presets, personas, and schedules.
- The deployed values come from the app-interface SaaS file `data/services/insights/kessel/kessel-ai-dev.yml` plus each legacy template's effective defaults. Only non-secret identity/routing values are copied into `env`.
- The legacy templates stay untouched: `deploy/template.yaml` (Kessel) and `deploy/gateway-template.yaml` (Gateway), including their KEDA `ScaledObject`s, NetworkPolicies, PostgreSQL sidecar, image parameters, and Slack secret wiring. Both app-interface targets use `ref: main`.
- Do not run dispatcher and legacy polling against the same instance at the same time.
- No secret values are committed or logged. Slack webhooks, Jira credentials, Git credentials, SSO credentials, and provider tokens remain deployment-owned.

## Deployed identity parity

| Setting | `instance/kessel` | `instance/gateway` |
| --- | --- | --- |
| Legacy template | `deploy/template.yaml` | `deploy/gateway-template.yaml` |
| `BOT_INSTANCE_ID` | `Oisín na Suthain-Shíor-Oibre` | `Matúš Čák Trenčiansky, Pán Siedmich Brán` |
| `BOT_LABEL` | `hcc-ai-kessel` | `hcc-gateway-ai` |
| Jira board | app-interface supplies `2379`; the Kessel template does not declare `BOT_BOARD_ID` — **configured-only drift** | `10850` (`BOT_BOARD_ID` in template and app-interface) |
| Backlog intake | `BOT_INCLUDE_BACKLOG=true` (app-interface overrides the template default) | `BOT_INCLUDE_BACKLOG=true` |
| Config path | `instance/kessel` | `instance/gateway` |
| Env presets | `node`, `go`, `slack`, `container-scan` | `slack` |
| Repo map | `project-repos.json` | `project-repos.json` |
| MCP | `mcp-atlassian` via deployment `JIRA_MCP_URL` | `mcp-atlassian` via deployment `JIRA_MCP_URL` |

The existing `project-repos.json`, `mcp.json`, personas, and `CLAUDE.md` content are preserved unchanged. The Kessel board-ID entry is the only configured identity that the deployed legacy template does not actually pass to the pod; this draft keeps the app-interface intent and labels the difference instead of editing GitOps or the legacy template.

## OpenCode routing

Both profiles select:

```yaml
runtime: opencode
provider: vertex
model: claude-opus-4-6
```

Evidence for this route:

- Both legacy templates use the Vertex proxy (`ANTHROPIC_VERTEX_BASE_URL=http://devbot-proxy:8443`, `EXECUTOR_ADDR=devbot-proxy:9090`), and both app-interface targets set `VERTEX_ALLOWED_MODELS` with `claude-opus-4-6`.
- The pinned dev-bot `config.json` uses `claude.model: claude-opus-4-6`, so this draft pins the model explicitly instead of relying on a workflow tier or provider default.
- The coordinator's packaged deployment config declares `claude-opus-4-6` under `vertex`; the profile loader accepts the runtime/provider/model shape.

**Native model roles are gated, not activated.** The requested Sol/Terra/Luna role split belongs to the `rehor-openai` route. The shared platform-frontend-ai-dev proxy target already declares an `OPENAI_ALLOWED_MODELS` map covering those models, and the shared dispatcher supplies a model-gateway URL, but none of that is evidence for this repository's legacy Deployment, runner image, or sandbox enrollment. At the pinned revision the packaged `rehor-openai` defaults declare Luna and Terra, not Sol; Sol also needs an instance `opencode-deployment.json` declaring it. This draft therefore does not reroute live traffic, does not broaden proxy permissions, and adds no per-model native agents. When the route is validated, use native subagents only for real roles (Sol for coordination/hard reasoning/review, Terra for implementation, Luna for bounded tasks) and keep the existing file-based personas as the single prompt source.

## Preflights

The upstream `jira-sprint` default set is `gh-pr-status` and `gl-mr-status`. Both profiles declare those plus `jira-sprint` with the instance label and `include_backlog: true`. All three ids are registered TypeScript preflights in the pinned revision and current upstream `master`; no core preflight is added.

**Open parity gaps:**

- The deployed Python runner receives `BOT_JIRA_EMAIL` from a Vault-backed secret key, and its sprint/backlog scan uses it for the bot-assigned candidate pass. `jira-sprint` exposes an optional literal `with.email`, but copying the deployment identity into `instance.yaml` would duplicate a deployment-owned value and drift on rotation. Rehor #678 / REHOR-278 supplies that deployment identity to the dispatcher's preflight context instead (merged `394edfd`, contained in the `f23332e` pin). The fallback is still dispatcher-side: it is active only once a dispatcher image containing that merge is deployed and a representative live cycle shows bot-assigned tickets are found. Until then the dispatcher scans unassigned candidates only and can miss bot-assigned tickets. No literal `with.email` is needed.
- `gl-mr-status` reaches GitLab through the services-gateway `/gitlab` API route. Gateway's existing GitLab clone credentials do not prove that API routing, so it remains a cutover gate.

## OpenCode guidance and native agents

- `instance/*/agent/AGENTS.md` are verbatim copies of the existing instance `CLAUDE.md`. The coordinator's OpenCode project loader rejects a profile layer that has `CLAUDE.md` but no `AGENTS.md`, and OpenCode does not apply Claude instruction assembly. The original `CLAUDE.md` files remain untouched for Claude rollback.
- Personas remain file-based: the `jira-sprint` workflow selects `personas/<name>/prompt.md` from the repo key. Neither instance has a native delegation requirement, so this draft adds no `.opencode/agents` roles or duplicate persona prompts; inventing per-model agents would broaden tool reach without a real role.

## Schedules

The legacy `ScaledObject` windows are mirrored literally because the dispatcher implements KEDA cron-window semantics (`docs/scheduling.md`; `packages/agent-dispatcher/src/schedule.ts`):

| Profile | Timezone | Start | End | Legacy source |
| --- | --- | --- | --- | --- |
| Kessel | `UTC` | `30 3 * * *` | `0 0 * * *` | `deploy/template.yaml` KEDA (`30 3` → `0 0`, daily) |
| Gateway | `UTC` | `0 7 * * 1-5` | `0 0 * * 1-5` | `deploy/gateway-template.yaml` KEDA defaults (`07:00`–`00:00`, Mon–Fri) |

The dispatcher gates new sessions only; in-flight sessions drain after a window closes. Because the gateway end expression excludes Saturday and Sunday, the window opened on Friday remains active until Monday `00:00` UTC under KEDA semantics. The dispatcher evaluates the same literal expressions and reproduced that boundary; the expressions were intentionally not "corrected". No KEDA `ScaledObject` or warm-pool configuration is added for dispatcher-managed agents.

## dev-bot pin

`dev-bot` moves from `150a350` to `f23332ec8e0030c5a2d1222b3f3f45e46b8a0b51`.

- `f23332e` is current upstream `master` (`fix(deps): update Grype to patch embedded Brotli`, #683). It contains everything the earlier draft pins provided: top-level profile `env` support (#668), registered TypeScript preflights, profile discovery with required `image`, KEDA-style schedule evaluation (#674), dispatcher-side bot Jira identity (#678), and one-unit `instanceEnv` delivery to preflights (#679).
- Between `6b4f296` and `f23332e` only these revisions affect the dispatcher or runner: `7df34e1` (Rehor #680 ports the Fabric Access workflow preflights and adds two optional `gh-pr-status` inputs), `b7da850` (Rehor #272/274 parses an optional `sandbox.env` category and renders tier-2 secret references at dispatch time), `bcb2c34` (Rehor #688 delivers rendered `sandbox.env` through the native sandbox environment), and `4cff10c` (Rehor #682 percent-encodes the bot instance identity header in the runner entrypoint). `f23332e` is a Grype dependency bump. None of them changes the declared `gh-pr-status`/`gl-mr-status`/`jira-sprint` parameters or the profile shape used here; both profiles declare no `sandbox.env`, so the secret-delivery path stays unused.
- Between `a113ed3` and `6b4f296` only two revisions affected this draft: `394edfd` (merged Rehor #678 / REHOR-278 dispatcher-side bot Jira identity and screenshot-upload helper) and `6b4f296` (REHOR-279 delivers the profile's approved top-level `env` to the registered TypeScript preflights as one read-only `instanceEnv` unit, never merged with the process environment, `sandbox.env`, or secret references). The revisions in between were CI workflow, image-reference, and `renovate.jsonc` chores; no other dispatcher or preflight source changes.
- These profiles keep their settings in the explicit `jira-sprint` `with:` parameters and in `env`. The new `instanceEnv` unit is an available delivery path, not a replacement, and none of the declared preflights consumes it yet, so no profile field changes with this pin.
- Moving the gitlink alone does not change the running image. The Kessel runner image must be rebuilt and published with this revision and the OpenCode V2 closure before dispatcher use.

## Validation performed

The validation harness ran against this checkout with the pinned Rehor revision `f23332e` built from source in a separate worktree, and completed without error. The harness called the real `discoverAgentProfiles`, `validateConfig` against `createPopulatedRegistry`, and `isScheduleActive` implementations. Results:

- exactly two profiles were discovered: `gateway` and `kessel`, with the intended identities, labels, config paths, image, env, and schedules;
- each profile's `env` was read as the preflight settings unit (instance ID, label, board, backlog, config path, engine) and passed the dispatcher's non-secret name eligibility rules, unchanged by the `instanceEnv` delivery;
- `gh-pr-status`, `gl-mr-status`, and `jira-sprint` resolved with their effective parameters and the same defaults as the previous pin; the registry gained the four Fabric Access preflights from Rehor #680, which these profiles do not declare;
- Kessel boundaries passed before/at `03:30`, before/at `00:00`, and on Sunday;
- Gateway boundaries passed before/at Monday `07:00`, Tuesday `00:00`, Friday `23:59`, Saturday/Sunday inside the Friday-opened window, and Monday `00:00`;
- the Python instance loader read `runtime: opencode`, `provider: vertex`, the env presets, and resolved `model=claude-opus-4-6` for both profiles;
- PyYAML parsed both profile files and both legacy templates, and `git diff --check` was clean.

The app-interface audit was read-only: YAML parse and `git diff --check` on the existing SaaS file, no app-interface validation tooling. Live Jira, GitHub, GitLab API routing, memory-server, proxy, Gateway, OpenShell sandbox, image, Slack delivery, and full cycle behavior are **not** validated.

## Gates before cutover

1. **Dispatcher and image compatibility:** deploy a dispatcher image containing `f23332e` (current `master`) and build/publish a Kessel runner image from the same revision with the OpenCode V2 closure. Confirm the configured `latest` tag resolves to that image, then pin the digest/tag. Do not infer compatibility from a floating tag.
2. **Bot-assigned candidate identity:** deploy a dispatcher containing Rehor #678 / REHOR-278 (`394edfd`, contained in the pin but not yet in any verified deployed image) and run representative live checks that bot-assigned sprint/backlog candidates are found, or obtain an explicit owner decision that unassigned-only intake is acceptable. The fallback is dispatcher-side.
3. **Services gateway and credentials:** configure the authenticated services gateway for Jira, GitHub, and GitLab API routes, complete the applicable security review (including REHOR-254), and verify `gl-mr-status` works for Gateway. Keep Slack delivery fail-closed until its deployment-owned webhook is verified; never expose or rename secret values.
4. **Native model routing:** only if the Sol/Terra/Luna split is adopted, declare Sol in an instance deployment config, confirm the shared allowlist/gateway for this image, add native agents only for real roles, and validate before changing `provider`/`model`.
5. **Schedule and isolation:** verify both profiles report off-schedule outside their windows, dispatch inside them, and never share instance IDs, labels, boards, sessions, or checkouts. Stop the legacy deployment for an instance before the dispatcher handles it.
6. **Cycle checks:** run a no-work cycle for each profile (no sandbox starts) and one representative work cycle per instance in an approved test/canary context, including Jira lifecycle, repo cloning, PR/MR creation, feedback handling, and cleanup.
7. **Human review:** review the profile diff, identities, schedules, routing, image reference, configured-only board drift, and rollback readiness. GitOps/app-interface enrollment remains a separate change.

Do not enroll this repository in the dispatcher until the gates pass and an owner approves the cutover.

## Rollback

1. Remove this configuration repository from the dispatcher's configured repository list and verify discovery is gone.
2. Restore any changed dispatcher image/template revision and, if the legacy deployment was stopped, its prior app-interface/GitOps configuration, replicas, KEDA windows, and image digest.
3. Restore the previous `dev-bot` gitlink and rebuild/redeploy the prior known-good image if a new image was promoted, then confirm only one execution path is active per instance.

The legacy deploy templates are untouched, so no template rollback is required.

## Draft limitations

- No dispatcher enrollment, image publication/promotion, app-interface/GitOps change, deployment, Jira write, or live cycle.
- `jira-sprint` bot-assigned parity requires a deployed dispatcher containing merged Rehor #678 (`394edfd`) — the pin contains it, no deployed image is confirmed to — plus representative live checks; native skills/commands, sandbox MCP, GitLab API routing, and Slack delivery are unproven; `latest` is a gate, not a verified artifact.
- Console Next PR #68 and HCC PR #121 are format/scope references only; this draft does not depend on their merge.
