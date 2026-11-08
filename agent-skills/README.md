# agent-skills

Versioned [Warp/Oz skills](https://docs.warp.dev/agent-platform/warp-agents/skills) for Murpheux's agents.

Skills live under `.agents/skills/<skill-name>/SKILL.md`. That path is one of the directories
Oz and local Warp agents scan for skill discovery, so any environment or repository that
includes this repo automatically exposes these skills.

## Layout

```
.agents/skills/
  analysis-artifacts/     SQL and visualization analysis artifacts
  ci-fix/                 GitHub Actions failure diagnosis
  composio-cli/           Composio CLI usage
  create-pull-request/    PR creation via gh
  dbt-model-index/        dbt/BigQuery model lookup
  docs-update/            Documentation upkeep
  ego-browser/            Browser automation with ego-lite
  github-bug-report-triage/
  github-issue-dedupe/
  mcp-builder/            MCP server scaffolding (FastMCP / MCP SDK)
  microsoft-foundry/      Foundry agents, models, evaluation
  scheduler/              On-device reminders and local scheduled actions
  seo-aeo-audit/          Search and AI-citation optimization
  slack-qa-investigate/   Read-only repo investigation
  terraform-style-check/  HashiCorp HCL style conventions
  web-accessibility-audit/WCAG compliance checks
  web-performance-audit/  Chrome DevTools performance profiling
  webapp-testing/         Playwright front-end testing
scripts/validate-skills.sh
```

## Usage

```zsh
make validate          # check every skill manifest
make list              # print skill names and descriptions

# Run a cloud agent from one of these skills
oz agent run-cloud -e <ENV_ID> --skill "murpheux/agent-skills:terraform-style-check" --prompt "review terraform/"

# Run locally
oz agent run --skill "murpheux/agent-skills:ci-fix" --prompt "diagnose the failing workflow"
```

## Adding a skill

```zsh
mkdir -p .agents/skills/<skill-name>
$EDITOR .agents/skills/<skill-name>/SKILL.md
make validate
```

`SKILL.md` requires YAML frontmatter with `name` (matching the directory) and `description`:

```markdown
---
name: <skill-name>
description: What it does and when to use it.
---

# <skill-name>

...
```

## Notes

- `ego-browser` is a point-in-time snapshot of `~/.local/share/ego/ego-skills`, which the local
  agent consumes as a symlink. Re-sync it here when the upstream skill changes.
- Keep skill directories small; only `SKILL.md` is required, and supporting files are loaded
  on demand.
