# Cline — cost-aware configuration (extension 4.1.x, legacy + next builds; CLI 3.0.x)

Since 4.1.0 the Cline extension ships **two builds** (`legacy` and `next`) with different config homes; the CLI shares everything with `next`. This setup targets both: rules, workflows and hooks go to `Documents/Cline` (read by both builds), and skills, subagents, the guard and MCP go to `~/.cline` (next + CLI). Pin `next` for predictability (`cline.rollout.bundleOverride`).

## Layout

```text
cline/
├── home/Documents/Cline/Rules/00-murpheux.md    full global instructions (always on; Cline-specific §13/§14/§17)
├── home/Documents/Cline/Workflows/*.md          16 workflows (/review.md, /plan.md, /security-scan.md, …)
├── home/Documents/Cline/Hooks/PreToolUse        guard launcher (macOS/Linux/WSL)
├── windows/PreToolUse.ps1                       guard launcher (Windows; installed by install.ps1)
├── home/.cline/skills/                          20 skills (~100 tokens each until used)
├── home/.cline/agents/*.yaml                    read-only subagents: explorer, reviewer, architect, security
├── home/.cline/guard/                           guard.py + guardrails.json (shared with every tool)
├── home/.cline/data/settings/cline_mcp_settings.json   MCP (secrets via op run)
├── home/.cline/{mcp.op.env,cline.op.env}        1Password references + legacy command deny list
├── templates/{.clineignore,vscode-settings.fragment.json}
└── install.sh / install.ps1
```

## Tiers (Plan/Act + subagents)

| Role | Where | Model |
|---|---|---|
| router, planner | Plan mode | OpenRouter `openai/gpt-6-sol` · high |
| developer, sre | Act mode | LiteLLM `claude-sonnet-5` · medium |
| explorer, reviewer | `subagent_*` (read-only) | LiteLLM `deepseek-flash` |
| architect | `subagent_architect` (read-only) | OpenRouter `openai/gpt-6-sol` |
| security | `subagent_security` (read-only) | OpenRouter `anthropic/claude-opus-5.5` |

Cost levers: rules are the only always-on context (guides are skills), cheap subagents for discovery/review, auto-condense on, `next` hard-blocks file-changing commands in Plan mode.

## Guardrails

- **Guard hook** on both builds (legacy `preToolUse` and next `tool_call` payloads) — cancels destructive, secret-reading, force-push and interactive commands, and secret-file reads/writes (`read_files`/`editor`/`apply_patch` included).
- **Subagents are read-only** by design: defined subagents do not inherit approval settings.
- **Approvals**: set Edit and Execute to require approval (next's defaults auto-approve edits and MCP).
- **Secrets**: providers.json stays key-free; keys come from `op run` env (`LITELLM_API_KEY`, `OPENROUTER_API_KEY`); MCP secrets are injected by `op run` wrappers.
- **Legacy extras**: `CLINE_COMMAND_PERMISSIONS` deny list and `.clineignore` (not a security boundary).

## About awesome-clinerules

The list is a copy of awesome-cursorrules (131 `.cursorrules` folders, last updated Jan 2025) and has nothing for .NET, PowerShell, bash, Terraform/Ansible, cloud, security or diagrams. Its useful ideas were adopted into the global rule and skills: verify-before-assuming and minimal-change discipline, answer-length control (cost), respecting existing architecture, stdlib-first Go, uv/ruff/pytest Python, strict TypeScript, and the project-notes/memory-bank pattern. The gaps were filled from Cline's own prompt collection (`cline/prompts`: security audit, Mermaid plans, memory bank) and the shared skills.

## Install

```bash
cd ~/agent-configs/cline && DRY_RUN=1 ./install.sh && ./install.sh       # macOS / WSL
pwsh -File install.ps1                                                  # Windows
```

> **Windows:** unsigned scripts on a `\\wsl.localhost\...` path are blocked by the RemoteSigned execution policy — copy the folder to a local drive first (`Copy-Item -Recurse \\wsl.localhost\Ubuntu\home\<you>\agent-configs\cline $env:USERPROFILE\agent-configs-cline`) and run `install.ps1` from there.
