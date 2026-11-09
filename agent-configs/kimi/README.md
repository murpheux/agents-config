# Kimi Code CLI - Murpheux's Global Configuration

> **Status: docs-verified (2026-11-09), not yet installed from this folder.** Checked against the Kimi Code CLI docs (kimi.com/code) and the
> installed binary (`kimi --version` = 2.5.2, data dir `~/.kimi-code`). Note: the older Python `kimi-cli` (`~/.kimi`, YAML agents) is
> a different product; only the Kimi Code pages apply here.

Configuration for `kimi`; models go through **Agentgateway** (`https://scarlet:9443/v1`).

## Layout

```text
kimi/
├── Makefile                 build · lint · test · install-dry · install (deploy)
├── install.sh               installs ONLY the config files below into ${KIMI_CODE_HOME:-~/.kimi-code}
├── lib/                     install-lib.sh, merge_json.py, normalize_eol.py (copy from _shared)
├── tests/test_config.py     offline structure/config/secret checks
└── home/.kimi-code/
    ├── AGENTS.md
    ├── agents/explorer.md
    ├── config.toml
    ├── hooks/kimi_guard.py
    ├── kimi-env.sh
    ├── skills/review/SKILL.md
    └── agents/ prompts-or-skills/ ...   (7 agents, 5 starter prompts/skills)
```

## Verified behaviour

| Fact | Result | Source |
|---|---|---|
| Installed version | `kimi --version` = **2.5.2**; binary `~/.kimi-code/bin/kimi`; flags `--agent`, `--agent-file`, `--plan`, `--skills-dir` | local CLI |
| Config | `~/.kimi-code/config.toml` (relocate with `KIMI_CODE_HOME`); `tui.toml`; project `<root>/.kimi-code/local.toml`; keys `default_model`, `providers`, `models`, `permission`, `hooks`, `extra_agent_dirs`, `extra_skill_dirs` | [config files](https://www.kimi.com/code/docs/en/kimi-code-cli/configuration/config-files.html) |
| Providers | `kimi provider add <registry-url>` / `catalog` / `list`; exact `[providers.*]` field names (`api_key_env`, `type`) **not confirmed**; run `kimi provider list` after install | local CLI help |
| Agents | Markdown + YAML in `~/.kimi-code/agents/` (or `~/.agents/agents/`), project `.kimi-code/agents/`; scanned recursively; fields `name`, `description` (required), `whenToUse`, `override`, `tools`, `disallowedTools`, `subagents` (default `coder`, `explore`, `plan`) | [agents](https://www.kimi.com/code/docs/en/kimi-code-cli/customization/agents.html) |
| Subagents | main agent dispatches automatically; each dispatch asks for approval unless allowed; background + resume supported | agents page |
| Skills | `~/.kimi-code/skills/`, `~/.agents/skills/`, project `.kimi-code/skills/`, `.agents/skills/` (`SKILL.md`) | [skills](https://www.kimi.com/code/docs/en/kimi-code-cli/customization/skills.html) |
| Custom slash commands | location **not documented** on the fetched pages | open |
| Hooks config | `[[hooks]]` in `config.toml` only (not project files); fields exactly `event`, `matcher` (regex), `command`, `timeout` (1-600 s, default 30); extra fields make the config fail to load | [hooks](https://www.kimi.com/code/docs/en/kimi-code-cli/customization/hooks.html) |
| Hook stdin | snake_case JSON: `hook_event_name`, `session_id`, `session_title`, `client_type`, `cwd` + event fields; Bash call exposes `tool_input.command` | hooks docs |
| Exit codes | `0` allow; **`2` block (stderr = reason)**; other non-zero allow; **timeout/crash fail open** | hooks docs |
| Stdout | `{"hookSpecificOutput":{"permissionDecision":"deny","permissionDecisionReason":"..."}}`; pairing with exit code not stated | hooks docs |
| Blockable events | only `PreToolUse`, `Stop`, `UserPromptSubmit` | hooks docs |

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

- **Guardrails**: `hooks/kimi_guard.py` runs the shared guard (copied byte-for-byte from `_shared/guardrails`) on every tool call; fail-closed.
- **Key**: never stored. The config names `AGENTGATEWAY_API_KEY`; `kimi-env.sh` fills it from 1Password (`op read`) per launch and
  unsets any public-provider variable that equals the gateway key.
- **Proxy/TLS**: wrapper adds `scarlet` to `NO_PROXY`; fix trust (CA bundle) rather than disabling verification.
- `.gitignore` excludes runtime state (`agent.db`, `sessions/`, `cache/`, `logs/`, credential files, `__pycache__`).

## Known gaps

- Hooks fail open on timeout/crash. `kimi_guard.py` maps its own errors to exit 2, but a hung guard cannot block; keep it fast.
- `matcher = ".*"` is valid regex; the tool names Kimi uses are not mapped to the shared guard's vocabulary yet.
- `commands/` is not a documented Kimi location; the 16 workflows may not load until the right directory (or skills) is confirmed.
- `[providers.agentgateway]` field names are unverified; check with `kimi provider list` and `kimi doctor` (validates hooks).
- Agent bodies are skeletons. Existing `~/.kimi-code/config.toml` is present and is backed up by the installer.

## Install

```zsh
cd ~/AI_Workspace/Projects/agents-config/agent-configs/kimi
make build && make install-dry && make install
echo 'source ~/.kimi-code/kimi-env.sh' >> ~/.dotfiles/config/zsh/.zshrc && exec zsh
```

## Troubleshooting

| Symptom | Check |
|---|---|
| `source config not found` | run `make build` (AGENTS.md is generated) |
| `401` / wrong provider | `type kimi` must say function; the gateway key resolves from 1Password |
| Hook blocks everything | `python3` missing or `hooks/guard.py` absent - reinstall (fail-closed by design) |
| TLS errors | trust the gateway CA in the OS keychain; never disable verification |
| Config fails to load | a `[[hooks]]` entry has an extra field; only `event`, `matcher`, `command`, `timeout` are allowed (`kimi doctor`) |
| Hook silently skipped | timeouts/crashes fail open; check the hook log and `timeout` |
| Hooks in project config ignored | hook rules are read from user `config.toml` and local plugins only |
