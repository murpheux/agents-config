# grok-cli — Murpheux's Global Configuration

Configuration for **grok-cli** (`@vibe-kit/grok-cli`, the open-source Node CLI — `grok --version` reports 1.0.1, its `package.json` 0.0.34), routed entirely through **Agentgateway** (`https://scarlet:9443/v1`). Every choice below was verified against the installed package (`dist/`, `README.md`); file references are to `dist/`.

grok-cli is minimal: one model per session, **no subagents, hooks, skills, or global MCP**, and one instruction file. The security layer therefore has to come from outside — a Node preload the wrapper loads.

## Layout

```text
grok/
├── Makefile                         build · lint · test · install-dry · install (deploy)
├── install.sh                       installs ONLY the CONFIG_FILES below into ~/.grok
├── lib/                             install-lib.sh, merge_json.py (from _shared) · build-ca-bundle.mjs · configure-settings.py
├── tests/{test_config.py,test-preload.mjs}   offline; the preload test drives grok-cli's real tool classes
└── home/.grok/
    ├── GROK.md                      global instructions — GENERATED from the OpenCode baseline (make build)
    ├── guard/{guard.py,guardrails.json}   GENERATED: byte-identical copy of _shared/guardrails
    ├── grok-env.sh                  `grok` wrapper (key, gateway, CA bundle, preload) — per process
    ├── grok-preload.cjs             guard + secret-free shells + gateway default model + request fix
    └── user-settings.fragment.json  applied to ~/.grok/user-settings.json by lib/configure-settings.py
```

## What grok-cli actually reads (verified)

| Item | Behaviour | Source |
|---|---|---|
| User settings | `~/.grok/user-settings.json`: `baseURL`, `apiKey`, `defaultModel`, `models`, `settingsVersion` (v2 migration prepends x.ai models if lower) | `utils/settings-manager.js` |
| Project settings | `.grok/settings.json` in the cwd — **auto-created** as `{"model":"grok-code-fast-1"}`; also holds `mcpServers` (MCP is project-only) | `settings-manager.js`, `mcp/config.js` |
| Model precedence | `-m` > `GROK_MODEL` > project `.grok/settings.json` > user `defaultModel` (the README's order omits the project file) | `index.js loadModel`, `getCurrentModel` |
| Key / URL | `GROK_API_KEY` before `apiKey`; `GROK_BASE_URL` before `baseURL`; `dotenv.config()` also loads the cwd `.env` (never overriding set vars) | `settings-manager.js`, `index.js` |
| Instructions | project `.grok/GROK.md` **replaces** `~/.grok/GROK.md` (not merged) | `utils/custom-instructions.js`, README |
| Requests | OpenAI SDK chat completions; always adds xAI `search_parameters`; `temperature: 0.7`; `max_tokens` = `GROK_MAX_TOKENS` or **1536** | `grok/client.js`, `agent/grok-agent.js` |
| Tools | `view_file`/`create_file`/`str_replace_editor` (fs-extra reads, `fs/promises` writes), `bash` (`promisify(child_process.exec)`), local ripgrep `search`; Morph `edit_file` only with `MORPH_API_KEY` (→ `api.morphllm.com`) | `tools/*.js` |
| Approvals | interactive confirmations for file writes/commands; **headless `-p` and `git commit-and-push` auto-approve all** | `utils/confirmation-service.js`, `index.js` |

`~/.grok/hooks/` and `~/.grok/skills/` (from herdr/orca) are not read by this grok-cli — there is no hooks or skills code in `dist/` — and are left untouched.

## How it is wired

- **Gateway**: the wrapper pins `GROK_BASE_URL=https://scarlet:9443/v1` and `GROK_API_KEY` (from `op read op://private/agent-gateway-api-key/password` at launch), so a project `.env` can't redirect the key. `install.sh` removes the plaintext `apiKey` from `user-settings.json` (backup first, value never printed) and replaces `models` with exact gateway ids that work over chat completions: `claude-sonnet-5` (default), `deepseek-flash`, `openrouter/openai/gpt-6-sol`, `openrouter/anthropic/claude-opus-5-5` (Claude 5.5 needs the Messages API and `gpt-6.1-sol` the Responses API, so they aren't listed).
- **Default model**: because the auto-created project file pins `grok-code-fast-1` (not on the gateway), the preload sets `GROK_MODEL=claude-sonnet-5` unless you pass `-m`, set `GROK_MODEL`, or the project already pins a gateway model (`/models` choices are kept).
- **Requests**: the preload strips `search_parameters` (xAI-only) from calls to the gateway; the wrapper raises `GROK_MAX_TOKENS` to 16384 and unsets `MORPH_API_KEY` (no file contents to Morph).
- **Guard**: `grok-preload.cjs` (via `NODE_OPTIONS=--require`, active only in the grok-cli process, removed from children) wraps `child_process.exec` (incl. its `promisify.custom`), `fs/promises` writes and fs-extra reads, then `module.syncBuiltinESMExports()` so the package's ESM imports see the wrappers. Each command/path is checked by the shared `guard.py`; `deny` **and** `ask` (git push, reset --hard, swarm removals, destructive SQL) are blocked, and a missing/broken guard blocks too. Shell commands run without gateway/API keys in their environment. This also covers headless `-p` and `git commit-and-push` (its `git push` is refused).
- **TLS**: `NODE_EXTRA_CA_CERTS=~/.grok/ca-bundle.pem` — the OS trust store (public roots + keychain-trusted gateway cert), built and verified against `scarlet:9443` by `install.sh`. `NO_PROXY` includes scarlet (only consulted if `NODE_USE_ENV_PROXY=1`).

## Install

```zsh
cd ~/AI_Workspace/Projects/agents-config/agent-configs/grok
make install-dry && make install
echo 'source ~/.grok/grok-env.sh' >> ~/.dotfiles/config/zsh/.zshrc && exec zsh
grok -m deepseek-flash -p "Reply with: ok"
```

## Troubleshooting

| Symptom | Check |
|---|---|
| `Grok API error: … model` / 404 | a project `.grok/settings.json` pins a non-gateway model and you passed it via `-m`; use a gateway id |
| `Connection error` / certificate errors | `whence -w grok` must say `function` (bare `command grok` has no CA bundle, key or guard) |
| `guardrails unavailable … blocked` | `~/.grok/guard/guard.py` or `python3` missing — `make install` |
| 400 from the gateway mentioning a field | report it — `temperature`/`tools` are sent as-is; only `search_parameters` is stripped |
| Project rules ignored | a project `.grok/GROK.md` replaces the global file entirely |
