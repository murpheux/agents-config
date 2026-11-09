# Google Antigravity CLI (agy) - Murpheux's Global Configuration

> **Status: partially docs-verified (2026-11-09); do not install yet.** Checked against antigravity.google docs and the installed binary
> (`agy --version` = 1.0.13). The shipped `hooks.json` and `agy_guard.py` do **not** match the documented contract and must be
> rewritten (see "Known gaps").

Configuration for `agy`; models go through **Agentgateway** (`https://scarlet:9443/v1`).

## Layout

```text
antigravity/
├── Makefile                 build · lint · test · install-dry · install (deploy)
├── install.sh               installs ONLY the config files below into ${AGY_CONFIG_DIR:-~/.gemini/config}
├── lib/                     install-lib.sh, merge_json.py, normalize_eol.py (copy from _shared)
├── tests/test_config.py     offline structure/config/secret checks
└── home/.gemini/config/
    ├── AGENTS.md
    ├── agents/explorer.md
    ├── agy-env.sh
    ├── hooks/agy_guard.py
    ├── hooks.json
    ├── mcp_config.json
    ├── skills/review/SKILL.md
    └── agents/ prompts-or-skills/ ...   (7 agents, 5 starter prompts/skills)
```

## Verified behaviour

| Fact | Result | Source |
|---|---|---|
| Installed version | `agy --version` = **1.0.13**; subcommands `plugin`, `models`, `update`, `install`; `--sandbox`, `--print` | local CLI |
| Settings | `~/.gemini/antigravity-cli/settings.json` (only non-default values stored; no hooks here) | [settings](https://antigravity.google/docs/settings/) |
| Hooks file | `~/.gemini/config/hooks.json` (global) or `<workspace>/.agents/hooks.json` | settings, [hooks](https://antigravity.google/docs/hooks?tab=cli) |
| Hooks schema | **map of hook name -> events**: `{ "<name>": { "enabled": true, "PreToolUse": [{ "matcher": "regex", "type": "command", "command": "...", "timeout": 30 }] } }`; events `SessionStart`, `PreToolUse`, `PostToolUse`, `PreInvocation`, `PostInvocation`, `Stop`; matcher only for tool events | hooks docs; matches the live `~/.gemini/config/hooks.json` |
| Hook stdin | camelCase JSON: `conversationId`, `workspacePaths`, `transcriptPath`, `modelName`, `lastUserInput`; tool events add `toolCall: { name, args }`, `stepIdx` | hooks docs |
| Hook stdout | PreToolUse **must print JSON** `{ "decision": "allow|auto_approve|deny|ask|force_ask|deny_unless_prior_grant", "reason": "..." }` | hooks docs |
| Exit codes | **not documented**; the contract is the stdout decision | hooks docs |
| Timeout | seconds, default 30 | hooks docs |
| Tool names | `run_command` (shell), `view_file`, `invoke_subagent` | hooks docs / search results |
| Subagents | `~/.gemini/config/agents/<name>.md` or `<name>/agent.md` (global), `.agents/agents/` (workspace); frontmatter `name`, `description`, `tools`, `mainAgent`, `subagent`, `model` (`inherit`/`flash`/`pro`), `commandExecutionPolicy` (`off|auto|eager|sandbox`), `mcpServers`, `skills`, `plugins`; called via `invoke_subagent`, picked in `/agents`, or `@name` | [subagents](https://antigravity.google/docs/subagents/) |
| MCP | `~/.gemini/config/mcp_config.json`, top-level `mcpServers`; `serverUrl` (not `httpUrl`), `timeoutSeconds` | settings docs, search results |
| Skills / commands / AGENTS.md | locations **not confirmed** (`~/.gemini/config/skills/` exists on disk) | open |
| Models | Google-hosted (`flash`/`pro`); custom OpenAI-compatible endpoints are not documented, so Agentgateway routing is unverified | docs |

## Agents & models

| Agent | Tier | Tools |
|---|---|---|
| explorer | small | read-only |
| reviewer | small | read-only + git |
| planner | large | read-only |
| developer | medium | all |
| sre | medium | read + shell |
| architect | large | read + docs writes |
| security | large | read + scanners |

Model IDs (`claude-sonnet-5`, `deepseek-flash` via the gateway) are unverified against the tool's provider docs; see Known gaps.

## Security

- **Guardrails**: `hooks/agy_guard.py` runs the shared guard (copied byte-for-byte from `_shared/guardrails`) on every tool call; fail-closed.
- **Key**: never stored. The config names `AGENTGATEWAY_API_KEY`; `agy-env.sh` fills it from 1Password (`op read`) per launch and
  unsets any public-provider variable that equals the gateway key.
- **Proxy/TLS**: wrapper adds `scarlet` to `NO_PROXY`; fix trust (CA bundle) rather than disabling verification.
- `.gitignore` excludes runtime state (`agent.db`, `sessions/`, `cache/`, `logs/`, credential files, `__pycache__`).

## Known gaps (must fix before install)

- `hooks.json` uses `{ "hooks": { "PreToolUse": [{ matcher, command }] } }`. The documented (and live) shape is `{ "<hook-name>": { "PreToolUse": [{ matcher, type: "command", command, timeout }] } }`. `install.sh` must **merge a named entry** into the existing file (it already holds herdr/orca entries), not overwrite it.
- `agy_guard.py` reads snake_case `tool_name`/`tool_input` and signals with exit 2. agy sends `toolCall.{name,args}` and expects a stdout `decision` JSON. Rewrite the adapter, map `run_command` to the shared guard's shell rule, and output `deny` for `ask`.
- Agent frontmatter lacks `tools`, `model`, `commandExecutionPolicy`, `subagent`/`mainAgent`; a wrong tool name can hang a subagent (documented), so list tools carefully.
- Commands and skills paths unverified; `agy-env.sh` gateway wiring unverified (no documented custom provider).
- `~/.gemini` also holds Gemini CLI state (`oauth_creds.json`, `settings.json`); never touch or print those.

## Install

```zsh
cd ~/AI_Workspace/Projects/agents-config/agent-configs/antigravity
make build && make install-dry && make install
echo 'source ~/.gemini/config/agy-env.sh' >> ~/.dotfiles/config/zsh/.zshrc && exec zsh
```

## Troubleshooting

| Symptom | Check |
|---|---|
| `source config not found` | run `make build` (AGENTS.md is generated) |
| `401` / wrong provider | `type agy` must say function; the gateway key resolves from 1Password |
| Hook blocks everything | `python3` missing or `hooks/guard.py` absent - reinstall (fail-closed by design) |
| TLS errors | trust the gateway CA in the OS keychain; never disable verification |
| Hook has no effect | wrong schema (must be a named entry); settings.json `hooks` key is never loaded |
| Hook output ignored | PreToolUse needs stdout JSON `decision`; exit code alone is not the documented contract |
| Subagent hangs | misspelled/unmapped tool in `tools:` (documented known issue) |
| Gemini CLI MCP server unreachable | use `serverUrl`/`timeoutSeconds`; `agy plugin import gemini` migrates |
