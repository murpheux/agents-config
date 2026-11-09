# Kiro CLI - Murpheux's Global Configuration

> **Status: partially docs-verified (2026-11-09); do not install yet.** Checked against kiro.dev docs and the installed binary
> (`kiro-cli --version` = 3.1.0). The hook stdin/exit-code contract for CLI V3 is **not documented** on the pages fetched, and the
> generated agent JSON still has skeleton prompts. See "Known gaps".

Configuration for `kiro-cli`; models go through **Agentgateway** (`https://scarlet:9443/v1`).

## Layout

```text
kiro/
├── Makefile                 build · lint · test · install-dry · install (deploy)
├── install.sh               installs ONLY the config files below into ${KIRO_HOME:-~/.kiro}
├── lib/                     install-lib.sh, merge_json.py, normalize_eol.py (copy from _shared)
├── tests/test_config.py     offline structure/config/secret checks
└── home/.kiro/
    ├── agents/explorer.json
    ├── hooks/kiro_guard.py
    ├── kiro-env.sh
    ├── permissions.yaml
    ├── prompts/review.md
    ├── settings/cli.json
    ├── steering/AGENTS.md
    └── agents/ prompts-or-skills/ ...   (7 agents, 5 starter prompts/skills)
```

## Verified behaviour

| Fact | Result | Source |
|---|---|---|
| Installed version | `kiro-cli --version` = **3.1.0** (flags `--v3`, `--v2`, `--tui`, `--agent`); `~/.kiro` exists with `agents/`, `hooks/`, `prompts/`, `permissions.yaml` | local CLI |
| Agent location | `~/.kiro/agents/` (global), `.kiro/agents/` (workspace); JSON, or Markdown with YAML frontmatter and prompt body | [config reference](https://kiro.dev/docs/custom-agents/configuration-reference/) |
| Agent fields | `name`, `description`, `prompt`, `mcpServers`, `tools`, `permissions`, `resources`, `hooks`, `includeMcpJson`, `model`, `welcomeMessage` | config reference |
| V3 permissions | `permissions.rules` with `allow`/`ask`/`deny` per capability (`fs_write`, `shell`); `allowedTools` is **CLI 2.x legacy** (`/upgrade-agent` converts) | config reference |
| Inline hook shape | array with PascalCase `trigger` (`PreToolUse`, `PostToolUse`), `name`, `matcher`, `action`; legacy camelCase (`preToolUse`) still accepted | config reference |
| Global hook files | `~/.kiro/hooks/*.json` loaded by V3: `{ "version": "v1", "hooks": [{ name, trigger, matcher, action: { type: "command"|"agent", command, timeout } }] }`; timeout default 60 s, `0` disables | [hooks](https://kiro.dev/docs/hooks/) |
| Hook stdin | "session context as JSON on STDIN"; PreToolUse example carries `hook_event_name`, `cwd`, `session_id`, `tool_name`, `tool_input` | hooks, [types](https://kiro.dev/docs/hooks/types/) |
| Exit codes | exit 0: stdout added to context; any other: stderr sent to the agent as an error; for PreToolUse the invocation is blocked. **Exit 2 specifically not documented** | [actions](https://kiro.dev/docs/hooks/actions/) |
| Steering / skills | default resources (steering, skills, `AGENTS.md`) inherited by custom agents; `skill://` loads metadata only; `file://` resources capped at 32 files / 100,000 chars | config reference |
| Default agent | setting key not covered on the fetched pages (`chat.defaultAgent` is from Phase 0) | open |

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

- **Guardrails**: `hooks/kiro_guard.py` runs the shared guard (copied byte-for-byte from `_shared/guardrails`) on every tool call; fail-closed.
- **Key**: never stored. The config names `AGENTGATEWAY_API_KEY`; `kiro-env.sh` fills it from 1Password (`op read`) per launch and
  unsets any public-provider variable that equals the gateway key.
- **Proxy/TLS**: wrapper adds `scarlet` to `NO_PROXY`; fix trust (CA bundle) rather than disabling verification.
- `.gitignore` excludes runtime state (`agent.db`, `sessions/`, `cache/`, `logs/`, credential files, `__pycache__`).

## Known gaps

- Hooks are written in the legacy camelCase single-command form (`"preToolUse": [{ "command": ... }]`). Under V3 use the documented `{ trigger: "PreToolUse", matcher, action: { type: "command", command } }` shape (or a `~/.kiro/hooks/*.json` file) and re-test.
- `kiro_guard.py` assumes exit 2 blocks. Docs say any non-zero exit blocks PreToolUse, so exit 2 is compatible, but test it with `kiro-cli --v3`.
- Agent `prompt` fields are skeleton text; `tools: ["*"]` should be replaced by per-role `tools` / `permissions.rules` (router gating).
- `permissions.yaml` and `settings/cli.json` keys (`chat.defaultAgent`, `trust:`) are not confirmed by the docs fetched.
- Models are Kiro-managed; the Agentgateway endpoint is not a documented provider for Kiro, so the `kiro-env.sh` gateway wiring is unverified.
- Existing `~/.kiro/agents/*.json` (+ `.bak`) are already present on this machine; the installer backs them up.

## Install

```zsh
cd ~/AI_Workspace/Projects/agents-config/agent-configs/kiro
make build && make install-dry && make install
echo 'source ~/.kiro/kiro-env.sh' >> ~/.dotfiles/config/zsh/.zshrc && exec zsh
```

## Troubleshooting

| Symptom | Check |
|---|---|
| `source config not found` | run `make build` (AGENTS.md is generated) |
| `401` / wrong provider | `type kiro_cli` must say function; the gateway key resolves from 1Password |
| Hook blocks everything | `python3` missing or `hooks/guard.py` absent - reinstall (fail-closed by design) |
| TLS errors | trust the gateway CA in the OS keychain; never disable verification |
| Hook ignored after upgrade | V3 prefers PascalCase triggers + `action`; run `/upgrade-agent` or rewrite |
| Agent cannot use a tool | `tools` selects visibility, `permissions` selects allow/ask/deny; `allowedTools` is legacy |
| Behaviour differs between engines | pass `--v3` or `--v2` explicitly; hooks/agents differ |
