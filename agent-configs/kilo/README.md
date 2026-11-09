# Kilo Code CLI - Murpheux's Global Configuration

> **Status: docs-verified (%s), not yet installed from this folder.** Facts below were checked against the official Kilo docs
> and the installed binary (`kilo --version` = 7.8.27). The generated agent bodies, skills wiring and the plugin guard are still
> placeholders; see "Known gaps" before running `make install`.

Configuration for `kilo`; models go through **Agentgateway** (`https://scarlet:9443/v1`).

## Layout

```text
kilo/
├── Makefile                 build · lint · test · install-dry · install (deploy)
├── install.sh               installs ONLY the config files below into ${KILO_CONFIG_DIR:-~/.config/kilo}
├── lib/                     install-lib.sh, merge_json.py, normalize_eol.py (copy from _shared)
├── tests/test_config.py     offline structure/config/secret checks
└── home/.config/kilo/
    ├── AGENTS.md
    ├── agents/explorer.md
    ├── command/review.md
    ├── guard/kilo_guard.py
    ├── kilo-env.sh
    ├── kilo.jsonc
    ├── plugin/guardrails.ts
    └── agents/ prompts-or-skills/ ...   (7 agents, 5 starter prompts/skills)
```

## Verified behaviour

| Fact | Result | Source |
|---|---|---|
| Installed version | `kilo --version` = **7.8.27**; npm package `@kilocode/cli` | local CLI, [kilo.ai/docs](https://kilo.ai/docs) |
| Global config | `~/.config/kilo/kilo.json` or `kilo.jsonc` (legacy `opencode.json[c]` also read); project: `./kilo.json[c]` or `./.kilo/`; project overrides global. `~/.config/opencode` is **no longer read** | [kilo.ai/docs/cli](https://kilo.ai/docs/cli) |
| Provider / model | `provider.<id>.options.{baseURL,apiKey}`, `provider.<id>.models`, `model: "provider/model"`; `{env:VAR}` works in global config only (ignored in project config) | kilo.ai/docs/cli |
| Permissions | `permission` key; `allow` / `ask` / `deny`, `"*"` catch-all, last matching rule wins | kilo.ai/docs/cli |
| Agents | Markdown + YAML frontmatter in `~/.config/kilo/agents/` (global) or `.kilo/agents/`; filename = agent name; fields `description`, `mode` (`subagent`/`primary`/`all`), `model`, `permission`, `hidden`, `steps`, `temperature`, `top_p`, `color`, `disable` | [custom-subagents](https://kilo.ai/docs/customize/custom-subagents) |
| Commands | **`~/.config/kilo/commands/`** (plural) and `.kilo/commands/`; frontmatter `description`, `agent`, `model`, `variant`, `subtask` | [workflows](https://kilo.ai/docs/customize/workflows) |
| Plugins | `~/.config/kilo/plugin/` (`plugins/` also accepted), auto-registered `.ts`/`.js`; default export `{ id, server }`; `tool.execute.before(input, output)` may mutate `output.args`; **blocking = throw an Error** (documented `.env` example) | [plugins](https://kilo.ai/docs/automate/extending/plugins) |
| Hook contract | In-process TS plugin, not stdin/exit-code. Block by throwing; no exit-code protocol | plugins page |
| Skills location | **Not confirmed** by the pages fetched (skills page not read) | open |

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

- **Guardrails**: `guard/kilo_guard.py` runs the shared guard (copied byte-for-byte from `_shared/guardrails`) on every tool call; fail-closed.
- **Key**: never stored. The config names `AGENTGATEWAY_API_KEY`; `kilo-env.sh` fills it from 1Password (`op read`) per launch and
  unsets any public-provider variable that equals the gateway key.
- **Proxy/TLS**: wrapper adds `scarlet` to `NO_PROXY`; fix trust (CA bundle) rather than disabling verification.
- `.gitignore` excludes runtime state (`agent.db`, `sessions/`, `cache/`, `logs/`, credential files, `__pycache__`).

## Known gaps (found during verification, not yet fixed in the generated files)

- `home/.config/kilo/command/` should be **`commands/`** (docs use the plural); `build.py`/installer need the rename.
- `plugin/guardrails.ts` still has a `TODO(verify)`; the throw-to-block mechanism matches the docs, but the `input.tool` / `output.args` shape and the guard's stdout JSON contract are untested against a live session.
- Agent files carry skeleton bodies and no `mode:`/`permission:` frontmatter yet; router gating relies on `permission` + the plugin.
- Skills directory not verified.
- `kilo` writes state under `~/.local/state/kilo`; under a sandbox set `XDG_STATE_HOME` or it fails with `EPERM` (reproduced).

## Install

```zsh
cd ~/AI_Workspace/Projects/agents-config/agent-configs/kilo
make build && make install-dry && make install
echo 'source ~/.config/kilo/kilo-env.sh' >> ~/.dotfiles/config/zsh/.zshrc && exec zsh
```

## Troubleshooting

| Symptom | Check |
|---|---|
| `source config not found` | run `make build` (AGENTS.md is generated) |
| `401` / wrong provider | `type kilo` must say function; the gateway key resolves from 1Password |
| Hook blocks everything | `python3` missing or `guard/guard.py` absent - reinstall (fail-closed by design) |
| TLS errors | trust the gateway CA in the OS keychain; never disable verification |
| `EPERM ... ~/.local/state/kilo/.kilo-write-*` | state dir not writable (sandbox); set `XDG_STATE_HOME`/`XDG_DATA_HOME` to a writable path |
| Config in `~/.config/opencode` ignored | Kilo no longer reads it; keep config in `~/.config/kilo` |
| `{env:AGENTGATEWAY_API_KEY}` empty | env substitution only works in global config, and the wrapper must export the key |
| Plugin guard blocks everything | a thrown error is the block signal; check `python3` and `guard/kilo_guard.py` |
