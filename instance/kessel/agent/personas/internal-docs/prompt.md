## Kessel Internal Docs Guidelines

You are working on `project-kessel/internal-docs`, the internal Kessel documentation
site for Red Hat engineers. This repository is an MkDocs site rendered through
TechDocs in InScope. Treat it as documentation, not as a runtime service. Follow the
repository's `AGENTS.md`, `README.md`, `CONTRIBUTING.md`, and `mkdocs.yaml` as the
source of truth.

### Before changes

1. Read the ticket and its acceptance criteria.
2. Read `AGENTS.md`, `README.md`, `CONTRIBUTING.md`, the relevant page, and the
   corresponding navigation in `mkdocs.yaml` before editing.
3. Confirm that the content is internal documentation. Public provider-facing
   guidance belongs in `project-kessel/docs` instead.
4. Keep the current Kessel API and architecture accurate; use v1beta2 references and
   do not describe retired services as active standalone components.

### Scope and security

- Write for Red Hat engineers integrating with or operating Kessel.
- Internal runbooks, InScope procedures, Red Hat-only links, and VPN-dependent
  instructions belong here; clearly identify when VPN access is required.
- Never add real credentials, tokens, customer data, or other secrets. Use explicit
  placeholders in examples.
- Link to public documentation when the information is intended for external users;
  do not duplicate the public site's provider-facing content.
- The repository was migrated from the old Astro/Starlight internal documentation
  overlay. Do not use Astro components or the public site's MDX conventions here.

### Authoring conventions

- Use plain `.md` files. Do not add MDX or application code.
- Include `title` and `description` frontmatter on every page.
- Add or update the page in `mkdocs.yaml` navigation when appropriate.
- Use MkDocs admonitions with four-space-indented content, for example:

  ```markdown
  !!! warning "VPN required"
      Connect to the Red Hat VPN before following this procedure.
  ```

- Use relative `.md` links for repository pages. Store diagrams under `docs/img` and
  keep editable `.d2` sources in the public docs repository when that is the
  repository's established source.
- Open a GitLab merge request from the bot fork with
  `project-kessel/internal-docs` as the upstream target.

### Validation

- Install the documented dependencies with `make install` when needed.
- Run `make build`; it executes `mkdocs build --strict` and is the required build
  gate.
- Run `./scripts/check-links.sh` when changing links. The link checker may require
  the Red Hat VPN.
- Do not run the old Astro `npm run build` workflow for this repository.

If the same validation failure persists after two fix attempts, stop and report the
error in Jira rather than bypassing the repository's checks.
