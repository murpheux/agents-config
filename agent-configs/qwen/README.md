# Qwen Code - Murpheux's Global Configuration

> **Status: docs-verified (2026-11-09), not yet installed from this folder.** Checked against the official Qwen Code docs and the installed
> binary (`qwen --version` = 0.27.1). The generated agent bodies are placeholders; see "Known gaps".

Configuration for `qwen`; models go through **Agentgateway** (`https://scarlet:9443/v1`).

## Layout

```text
qwen/
├── Makefile                 build · lint · test · install-dry · install (deploy)
├── install.sh               installs ONLY the config files below into ${QWEN_HOME:-~/.qwen}
├── lib/                     install-lib.sh, merge_json.py, normalize_eol.py (copy from _shared)
├── tests/test_config.py     offline structure/config/secret checks
└── home/.qwen/
    ├── AGENTS.md
    ├── agents/explorer.md
    ├── hooks/qwen_guard.py
    ├── qwen-env.sh
    ├── settings.json
    ├── skills/review/SKILL.md
    └── agents/ prompts-or-skills/ ...   (7 agents, 5 starter prompts/skills)
```

## Verified behaviour

| Fact | Result | Source |
|---|---|---|
| Installed version | `qwen --version` = **0.27.1** | local CLI |
| User settings | `~/.qwen/settings.json`; project `.qwen/settings.json` | [settings docs](https://qwenlm.github.io/qwen-code-docs/en/users/configuration/settings/) |
| `context.fileName` | string or array, default undefined (so `AGENTS.md` must be listed explicitly, as the skeleton does) | settings docs |
| `modelProviders` schema | `envKey` + HTTPS `baseUrl` per route confirmed only for the image-model route; the `openai[]` entry shape is **not confirmed** on the fetched pages | settings docs (partial) |
| Subagents | Markdown + YAML in `~/.qwen/agents/` (user) / `.qwen/agents/` (project wins); fields `name`, `description`, `model` (`inherit`/`fast`/id), `approvalMode`, `tools`, `disallowedTools` | [sub-agents](https://qwenlm.github.io/qwen-code-docs/en/users/features/sub-agents/) |
| Commands | `~/.qwen/commands/` and `.qwen/commands/`; Markdown with optional frontmatter (TOML deprecated) | [commands](https://qwenlm.github.io/qwen-code-docs/en/users/features/commands/) |
| Skills | project `.qwen/skills/<name>/SKILL.md` confirmed; user-level `~/.qwen/skills` not stated | settings docs |
| Hooks config | `hooks.<Event>[] -> { matcher, hooks: [{ type: "command", command, timeout }] }` in settings; enabled by default, `disableAllHooks` turns off; project hooks need folder trust | [hooks](https://qwenlm.github.io/qwen-code-docs/en/users/features/hooks/) |
| Hook stdin | JSON: `session_id`, `transcript_path`, `cwd`, `hook_event_name`, `timestamp`, `permission_mode`, plus `tool_name`, `tool_input`, `tool_use_id` for PreToolUse | hooks docs |
| Exit codes | `0` success (stdout JSON honoured); **`2` blocking, stderr to the model**; other = non-blocking, execution continues | hooks docs |
| Stdout decision | `hookSpecificOutput.{hookEventName, permissionDecision: allow|deny|ask, permissionDecisionReason}` | hooks docs |

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

- **Guardrails**: `hooks/qwen_guard.py` runs the shared guard (copied byte-for-byte from `_shared/guardrails`) on every tool call; fail-closed.
- **Key**: never stored. The config names `AGENTGATEWAY_API_KEY`; `qwen-env.sh` fills it from 1Password (`op read`) per launch and
  unsets any public-provider variable that equals the gateway key.
- **Proxy/TLS**: wrapper adds `scarlet` to `NO_PROXY`; fix trust (CA bundle) rather than disabling verification.
- `.gitignore` excludes runtime state (`agent.db`, `sessions/`, `cache/`, `logs/`, credential files, `__pycache__`).

## Known gaps

- `qwen_guard.py` already matches the verified contract (stdin `tool_name`/`tool_input`, exit 2 blocks). Qwen tool names (`run_shell_command`, `write_file`, ...) are not mapped to the shared guard's Bash/Write vocabulary, so verify the mapping before relying on it.
- `modelProviders.openai[]` keys (`id`, `baseUrl`, `envKey`) are unconfirmed; run `qwen` once and check `/model`.
- Agent bodies are skeletons; user-level skills path unconfirmed.
- Hook exits other than 0/2 fail open (documented), so a crashing guard would not block; `qwen_guard.py` maps its own errors to exit 2.

## Install

```zsh
cd ~/AI_Workspace/Projects/agents-config/agent-configs/qwen
make build && make install-dry && make install
echo 'source ~/.qwen/qwen-env.sh' >> ~/.dotfiles/config/zsh/.zshrc && exec zsh
```

## Troubleshooting

| Symptom | Check |
|---|---|
| `source config not found` | run `make build` (AGENTS.md is generated) |
| `401` / wrong provider | `type qwen` must say function; the gateway key resolves from 1Password |
| Hook blocks everything | `python3` missing or `hooks/guard.py` absent - reinstall (fail-closed by design) |
| TLS errors | trust the gateway CA in the OS keychain; never disable verification |
| Hook never fires | project hooks need folder trust; check `disableAllHooks` is not set |
| Guard crash lets a call through | only exit 2 blocks; other non-zero codes are non-blocking by design |
| Model list empty | `modelProviders` entry shape unverified; inspect with `/model` |
