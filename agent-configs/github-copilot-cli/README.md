# GitHub Copilot CLI — cost-aware configuration (v1.0.6x)

The CLI supports every piece the OpenCode design needs: custom agents with tool restrictions, per-subagent model/effort tiers (`subagents.agents` in `settings.json`), personal instructions, skills, `preToolUse` hooks, MCP, a sandbox, and (optionally) managed deny/ask/allow rules. `~/.copilot` is **shared with VS Code's Copilot agent harness**, so this folder and `vscode/` install identical instructions, skills and hooks; agents are target-scoped (`github-copilot` here, `vscode` there) so each tool lists only its own flavour.

## Layout

```text
github-copilot-cli/
├── home/.copilot/settings.fragment.jsonc     merged into ~/.copilot/settings.json (model tiers, sandbox, deniedUrls, remote off…)
├── home/.copilot/instructions/murpheux.instructions.md   global instructions (applyTo **; CLI + VS Code)
├── home/.copilot/agents/*.agent.md           router, explorer, reviewer, planner, developer, sre, architect, security
├── home/.copilot/skills/                     20 portable skills + 13 workflow skills
├── home/.copilot/hooks/{guard.json,guard.py,guardrails.json}   preToolUse guard (fail-closed on crash)
├── home/.copilot/mcp-config.json             context7, mslearn, awsdocs, terraform (GitHub MCP is built in)
├── home/.copilot/copilot-aliases.{sh,ps1}    cop, cop-dev, cop-sre, cop-plan, cop-sec, cop-cheap, cop-cap
├── managed/managed-settings.json             optional root-owned deny/ask/allow policy (install.sh --managed)
└── install.sh / install.ps1
```

## Tiers

| Agent | Model · effort | Tools |
|---|---|---|
| router (`cop`) | deepseek-flash | agent, read, search, web, todo — cannot edit or run shell |
| explorer / built-in explore, task | deepseek-flash · low | read-only / builds & tests |
| reviewer / built-in code-review | deepseek-flash · medium | read, search, execute |
| planner | openrouter/openai/gpt-6-sol · medium | read-only + agent |
| developer, sre, general-purpose | claude-sonnet-5 · medium | all / ops |
| architect | openrouter/openai/gpt-6-sol · high | read + docs edits |
| security | openrouter/anthropic/claude-opus-5-5 · high | read + scanners |

Spend visibility: footer shows AI credits used, context and agent; `/usage`, `/context`; `cop-cap` sets `--max-ai-credits`. All ids are **Agentgateway** model IDs: the `cop*` aliases run Copilot in BYOK mode against `https://scarlet:9443/v1` (OpenAI chat completions), so GitHub's model catalog and AI credits don't apply. One provider serves every agent — each id must exist on the gateway (planner/architect/security use its `openrouter/*` passthrough). TLS: the aliases point `NODE_EXTRA_CA_CERTS` at `~/.copilot/ca-bundle.pem` (OS trust store incl. the home-lab CA, built by `install.sh`).

## Guardrails

1. **Router can't mutate** — its `tools` omit edit/execute, so it must delegate.
2. **Guard hook** — `preToolUse` runs `guard.py`; exit 2 denies, and the CLI fails *closed* if the hook crashes.
3. **Sandbox** — shell/MCP/file tools sandboxed; `~/.ssh`, `~/.aws`, `~/.gnupg`, `~/.config/op`, kube/docker configs, AI-tool credential files denied (macOS/Linux).
4. **Secrets** — `--secret-env-vars` (in the aliases) strips gateway/API tokens from shell and MCP environments and redacts them; `deniedUrls` blocks common exfiltration endpoints.
5. **No bypass** — `disableBypassPermissionsMode: allow-auto-only` refuses `--yolo`/`--allow-all`; `remote: off` keeps sessions local.
6. **Optional managed policy** — true deny/ask/allow rules the model cannot bypass (root-owned file).

## awesome-copilot

`copilot plugin` ships with the **awesome-copilot marketplace built in**. Worth installing: `csharp-dotnet-development`, `aws-cloud-development` / `azure-cloud-development`, `devops-oncall`, `structured-autonomy` ("premium planning, thrifty implementation"). Ideas adopted natively: the *rug-orchestrator* pure-coordinator router, *tool-guardian* / *secrets-scanner* hooks (→ `guard.py`), security/threat-model/diagram skills (→ shared skills), *terraform-iac-reviewer* and *platform-sre-kubernetes* agents (→ `security`/`sre`). Browse: `copilot plugin marketplace browse awesome-copilot`.

## Install

```bash
cd ~/agent-configs/github-copilot-cli && DRY_RUN=1 ./install.sh && ./install.sh     # macOS / WSL
pwsh -File install.ps1                                                              # Windows
```

> **Windows:** unsigned scripts on a `\\wsl.localhost\...` path are blocked by the RemoteSigned execution policy — copy the folder to a local drive first (`Copy-Item -Recurse \\wsl.localhost\Ubuntu\home\<you>\agent-configs\github-copilot-cli $env:USERPROFILE\agent-configs-github-copilot-cli`) and run `install.ps1` from there.
