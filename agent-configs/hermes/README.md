# Hermes Agent — Murpheux's Global Configuration

Configuration for [Hermes Agent](https://github.com/NousResearch/hermes-agent) (v0.21.x, git install at `~/.hermes/hermes-agent`). Every choice below was checked against the installed source and its bundled docs (`~/.hermes/hermes-agent/website/docs/`); file references are to that checkout. All models go through **Agentgateway** (`https://scarlet:9443/v1`).

## Layout

```text
hermes/
├── Makefile                          build · lint · test · install-dry · install (deploy)
├── install.sh                        installs ONLY the files below into ${HERMES_HOME:-~/.hermes}; merges Hermes-owned files
├── lib/                              install-lib.sh, merge_json.py (from _shared) · build-ca-bundle.mjs · configure-hermes.py
├── tests/test_config.py              offline checks run with Hermes' own interpreter and code
└── home/.hermes/
    ├── SOUL.md                       global instructions — GENERATED from the OpenCode baseline (make build)
    ├── config.fragment.yaml          merged into config.yaml: gateway provider, models, hook, skills, approvals
    ├── hermes-env.sh                 `hermes` wrapper: gateway bypasses inherited proxies (herdr/tmux)
    ├── agent-hooks/guardrails-hook.py   pre_tool_call shell hook → shared guard (fail-closed)
    ├── guard/{guard.py,guardrails.json} GENERATED: byte-identical copy of _shared/guardrails
    └── skills/
        ├── murpheux-roles/role-*/        GENERATED: developer, planner, sre, architect, reviewer, security
        └── murpheux-workflows/wf-*/      GENERATED from _shared/commands.yaml: /wf-review /wf-commit /wf-plan …
```

Build spec: `_shared/tools/hermes.yaml`. Topic skills (`golang`, `terraform`, …) are **not** duplicated: `skills.external_dirs: [~/.agents/skills]` reads the Codex-installed copies (`user-guide/features/skills.md` "external_dirs").

## How Hermes maps to this repo's design

| Concern | Hermes mechanism (verified) | Here |
|---|---|---|
| Global instructions | `SOUL.md` is the only `HERMES_HOME` instruction slot, always loaded; `AGENTS.md` is project-only, first match of `.hermes.md` → `AGENTS.override.md` → `AGENTS.md` → `CLAUDE.md` (`user-guide/features/context-files.md`; `agent/prompt_builder.py` `load_soul_md`) | generated `SOUL.md` |
| Truncation | context files are head/tail-cut at `context_file_max_chars`, default floor 20 000 (`prompt_builder.py:1062-1083`) — SOUL.md is ~28 KB | `context_file_max_chars: 40000` |
| Injection scan | SOUL.md in your own home is warn-only (`prompt_builder.py:81`) | test runs the real scanner: no findings |
| Subagents | `delegate_task` spawns generic children (goal + context only); `delegation.model` is a single global pin (`features/delegation.md:264-292`) — no named roles | the 7 specialists are **role skills**; the router tells a child "load `role-<x>`" |
| Slash prompts | "For reusable prompt workflows, create a skill" (`user-guide/configuration.md` Quick Commands); `/plan`, `/review`, `/image` are built-ins | 16 workflows as `wf-*` skills (test asserts no collision with `hermes_cli/commands.py` `COMMAND_REGISTRY`) |
| Auxiliary models | each task defaults to `auto` = main model; never falls back to another account (`user-guide/configuring-models.md:87`) | title generation + compression → `main` provider, `deepseek-flash` |

## Gateway, key, TLS, proxy

- **Provider** — named `providers.agentgateway` (`api`, `transport: chat_completions`, `discover_models: false`, exact gateway ids), selected with `model.provider: custom:agentgateway` (`hermes_cli/runtime_provider_custom.py:96-133`). Only ids the gateway serves over chat completions: Claude 5.5 needs the Messages API and `gpt-6.1-sol` the Responses API, so they're reached via `claude-sonnet-5` and the `openrouter/*` passthrough. Default: `claude-sonnet-5`. Switch: `/model custom:agentgateway:<id>`.
- **Key** — `key_cmd: "<abs op> read op://private/agent-gateway-api-key/password"`. Hermes runs it itself (shell, 15 s timeout, re-minted every 15 min, output never logged — `agent/command_token_source.py`), and `key_cmd` beats `key_env`/`api_key`, also for auxiliary tasks (`integrations/providers.md` "Command-minted credentials"). No key is stored in config, `.env` or this repo; `install.sh` removes a plaintext `AGENTGATEWAY_API_KEY` line from `~/.hermes/.env` (names reported, never values).
- **TLS** — Hermes' httpx `verify` is per-provider `ssl_ca_cert` > `HERMES_CA_BUNDLE` > `SSL_CERT_FILE` > … > certifi (`agent/ssl_verify.py:36`), never the keychain. The provider pins `ssl_ca_cert: ~/.hermes/ca-bundle.pem` — the OS trust store (public roots + the keychain-trusted gateway cert), built and verified against `scarlet:9443` by `install.sh`. Scoped to this provider only.
- **Proxy** — httpx honours `HTTP(S)_PROXY`; panes of a long-lived herdr/tmux server can inherit a dead one. `hermes-env.sh` adds the gateway hosts to `NO_PROXY` (CLI only — the desktop app and `hermes gateway` service don't use it).

## Guardrails

`hooks.pre_tool_call` runs `agent-hooks/guardrails-hook.py` on `terminal`, `read_file`, `search_files`, `write_file` and `patch` (every path in a V4A `patch`, same header grammar as `tools/file_tools.py:145-146`). It speaks Hermes' shell-hook JSON (`features/hooks.md` "Shell Hooks", `agent/shell_hooks.py`) and runs the shared guard. Shell hooks can only `block`/`modify` — not `approve` (`shell_hooks.py:407`) — so approval-required rules (`git push`, `git reset --hard`, `docker stack rm`, destructive SQL) are blocked with a hand-off message; Hermes' own `approvals.mode: manual` prompts for its dangerous-command list on top. `fail_closed: true` plus the adapter's own error handling block the call if the guard is missing, crashes or times out.

Consent: Hermes asks once per `(event, command)` and, in non-TTY runs (gateway, cron), **silently skips** unapproved hooks — i.e. fails open. `install.sh` therefore writes the documented manual allowlist entry to `~/.hermes/shell-hooks-allowlist.json` with the exact command string (`features/hooks.md` "Consent model"). Verify with `hermes hooks list` / `hermes hooks doctor`.

## Install

```zsh
cd ~/AI_Workspace/Projects/agents-config/agent-configs/hermes
make install-dry          # preview
make install              # lint + test + install (= make deploy)
echo 'source ~/.hermes/hermes-env.sh' >> ~/.dotfiles/config/zsh/.zshrc && exec zsh
hermes hooks list && hermes chat -q "Reply with: ok"
```

`install.sh` backs up `config.yaml`, `shell-hooks-allowlist.json`, `.env` and every file it replaces (including your current `SOUL.md`) to `~/.agent-config-backups/hermes-<timestamp>/`.

## Troubleshooting

| Symptom | Check |
|---|---|
| `key_cmd … exited 1` / `timed out after 15s` | 1Password locked or its approval prompt not answered within 15 s — unlock and retry. |
| `CERTIFICATE_VERIFY_FAILED` | `~/.hermes/ca-bundle.pem` missing/stale → `make install`. |
| `All connection attempts failed` (herdr/tmux pane) | Pane inherited a dead proxy: `source ~/.hermes/hermes-env.sh`, or restart the multiplexer from a clean shell. |
| Hook not running | `hermes hooks doctor` (allowlist, exec bit); re-run `make install`. |
| `Blocked by guardrails …` | Intentional — change `_shared/guardrails/guardrails.json`, then `make build` (never edit the copy here). |
| Agent edited a shared skill | `external_dirs` are not write-protected (`features/skills.md`); reinstall the Codex config to restore. |
