# VS Code (GitHub Copilot Chat agent mode) — cost-aware configuration (VS Code 1.139+)

VS Code 1.139 has two agent harnesses: **Local** (extension host; reads profile prompt files and settings) and **Copilot** (Agent Host; reads only `~/.copilot` and `~/.claude`). This folder configures both: the shared `~/.copilot` core (identical to the Copilot CLI folder) plus VS Code-flavoured agents (`target: vscode`, handoffs, model fallbacks), profile prompt files, `settings.json` approvals/sandbox, and `mcp.json`.

## Layout

```text
vscode/
├── home/.copilot/agents/vscode-*.agent.md          Router, Explorer, Reviewer, Planner, Developer, SRE, Architect, Security
├── home/.copilot/instructions/murpheux.instructions.md   global instructions (both harnesses + CLI)
├── home/.copilot/skills/                           20 portable skills (Agent Skills spec)
├── home/.copilot/hooks/                            guard.json + guard.py + guardrails.json (PreToolUse guard)
├── home/.copilot/{mcp-config.json,mcp.op.env}      MCP for the Copilot harness (+ 1Password refs)
├── home/vscode-profile/settings.fragment.jsonc     merged into <profile>/settings.json
├── home/vscode-profile/mcp.json                    MCP for the Local harness (secrets via op run, no ${input:})
├── home/vscode-profile/prompts/*.prompt.md         16 prompt files (/review, /plan, /security-scan, …) — Local harness
└── install.sh (macOS/Linux/WSL) / install.ps1 (Windows)
```

## Routing & cost

| Agent | Model (fallbacks) | Role |
|---|---|---|
| **Router** | Claude Sonnet 5 → GPT-6 Sol → Auto | triage; tools read/search/web/todo/agent only |
| Explorer (subagent) | GPT-6 Luna → Claude Haiku 5.5 → Auto | cheapest discovery |
| Reviewer (subagent) | GPT-6 Luna → Claude Haiku 5.5 → Auto | diff review |
| Planner (subagent) | GPT-6 Sol → Claude Sonnet 5 · medium | plans |
| Developer / SRE (subagents) | Claude Sonnet 5 → GPT-6 Sol · medium | implementation / ops |
| Architect (**handoff**) | Claude Opus 5.5 → GPT-6 Sol · high | premium design |
| Security (**handoff**) | Claude Opus 5.5 → GPT-6 Sol · high | premium HIGH_RISK review |

VS Code **refuses subagents priced above the calling agent**, so the Router sits on the Medium tier and the premium specialists are **handoff buttons** — escalation is explicit and user-confirmed, which is exactly the "escalate only on evidence" rule. Prompt files for cheap tasks (`/commit`, `/explain`, `/summarize`, `/pr`) pin GPT-6 Luna. Copilot bills in **AI credits** (token-based since 2026-06-01); Auto gets a 10% discount.

## Guardrails

- **Terminal auto-approve**: only read-only/validation commands auto-run; destructive, cloud, push and `.ps1` commands always ask (`false` = ask, not block).
- **Guard hook** (`~/.copilot/hooks/guard.json`): actually **blocks** destructive, secret-reading, force-push and interactive commands and secret-file edits — shared with the Copilot CLI.
- **Edit protection**: `.env*`, state/keys, workflows and `.ssh` edits always ask (VS Code also protects `.git/**`, `package.json`, lockfiles, `.vscode/*.json` by default).
- **Sandbox**: terminal sandbox on for macOS/Linux/WSL2; workspace npm scripts no longer auto-approved; web fetch not auto-approved (prompt-injection surface).
- **No double instructions**: `chat.useClaudeMdFile: false` so `~/.claude/CLAUDE.md` isn't loaded on top of the Copilot instructions.

## awesome-copilot highlights

The awesome-copilot marketplace is built into VS Code (`@agentPlugins`). Recommended plugins: `csharp-dotnet-development`, `aws-cloud-development`, `azure-cloud-development`, `devops-oncall`, `structured-autonomy`. Adopted natively: *rug-orchestrator* (pure-coordinator router), *se-security-reviewer*, *se-system-architecture-reviewer*, *terraform-iac-reviewer*, *platform-sre-kubernetes* (→ Security/Architect/SRE agents), *tool-guardian* / *secrets-scanner* hooks (→ guard), draw.io/threat-model/ADR skills (→ shared skills). Large always-on instructions such as `security-and-owasp` (1,088 lines, `applyTo: **`) were deliberately converted to on-demand skills.

## Install

```bash
cd ~/agent-configs/vscode && ./install.sh              # macOS / Linux / WSL (~/.copilot + remote settings)
pwsh -File install.ps1                                  # Windows (profile + %USERPROFILE%\.copilot)
```

> **Windows:** unsigned scripts on a `\\wsl.localhost\...` path are blocked by the RemoteSigned execution policy — copy the folder to a local drive first (`Copy-Item -Recurse \\wsl.localhost\Ubuntu\home\<you>\agent-configs\vscode $env:USERPROFILE\agent-configs-vscode`) and run `install.ps1` from there.
