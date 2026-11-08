# agent-configs — one design, seven AI coding agents

The cost-aware multi-agent setup built for OpenCode (`opencode/.config/opencode` — the baseline every other tool is generated from), re-implemented natively for six more tools. Every folder mirrors the tool's real home-directory layout and has its own `install.sh` (+ `install.ps1` where Windows matters) that backs up anything it replaces into `~/.agent-config-backups/`.

| Folder | Tool (version verified) | Router mechanism | Enforcement |
|---|---|---|---|
| `opencode/` | OpenCode 2.0.18 (baseline) | primary `router` agent; edit/shell denied | hard-deny policies, ordered permissions |
| `claude-code/` | Claude Code 2.1.28x | main session runs as `router` agent (Haiku); hook keeps it read-only | deny rules, guard hook, OS sandbox, env scrub |
| `github-copilot-cli/` | Copilot CLI 1.0.6x | `copilot --agent router` (no edit/shell tools) | guard hook (fail-closed), sandbox, deniedUrls, optional managed deny rules |
| `vscode/` | VS Code 1.139 Copilot Chat | Router agent: subagents + premium handoffs | terminal/edit auto-approve rules, guard hook, sandbox |
| `cline/` | Cline 4.1.x (legacy + next) / CLI 3.0.x | Plan mode + read-only subagents | guard hook (both builds), approvals, legacy deny list |
| `codex/` | Codex CLI 0.157.x | main thread + custom agents + profiles | sandbox, exec-policy rules, guard hook, env filtering |
| `aider/` | Aider 0.86.x | aliases/modes (`ai`, `ai-ask`, `ai-arch`, `ai-sec`) | Aider options, pre-commit verify, `.aiderignore` |

## Shared source of truth (`_shared/`)

```text
_shared/
├── build.py            renders every tool from the sources below (run after any change)
├── validate.py         parses JSON/JSONC/TOML/YAML/frontmatter, checks skill spec, Codex rules, CRLF, placeholders
├── install_smoke.sh    runs every installer against a throwaway $HOME and exercises the hooks
├── AGENTS.template.md  generated from opencode/.config/opencode/AGENTS.md (all content kept; tool placeholders)
├── agents/*.md         router + 7 specialist prompt bodies (tool-neutral)
├── commands.yaml       16 workflows → Claude commands, VS Code prompt files, Cline workflows, Codex/Copilot skills
├── skills/             20 portable skills (Agent Skills spec), generated from the OpenCode skills
├── guardrails/         guardrails.json (33 command rules, 18 protected paths) + guard.py (one hook, 5 tool contracts)
├── tools/<tool>.yaml   per-tool rendering spec (placeholders, agents, models, command format)
├── install-lib.sh, merge_json.py, normalize_eol.py
```

```bash
cd ~/agent-configs
python3 _shared/build.py            # regenerate all tools (also normalises line endings)
python3 _shared/validate.py         # offline validation
bash _shared/install_smoke.sh       # installer + hook smoke tests in temp HOMEs
```

## Coexistence (installing several tools on one machine)

- `~/.copilot` is shared by the Copilot CLI and VS Code's Copilot harness: both folders install the **same** instructions, skills and hook; agents are target-scoped (`github-copilot` vs `vscode`) so each tool lists only its own.
- `~/.agents/skills` (Codex) is also read by the Copilot CLI and Cline next; the Copilot/VS Code installers skip identical copies. Codex workflow skills live in Codex-only `~/.codex/skills`.
- VS Code's Copilot harness also reads `~/.claude/agents` and `~/.claude/skills`; `chat.useClaudeMdFile` is disabled so `CLAUDE.md` isn't loaded twice.
- Every tool uses the same `guardrails.json`, so a rule change is one edit + `build.py`.

Reports: `reports/*.pdf` (one per tool + `00-final-report.pdf`).
