# oh-my-pi (omp) — Murpheux's Global Configuration

Configuration for [oh-my-pi](https://github.com/can1357/oh-my-pi) (`omp` 18.x, Homebrew), a Pi fork that — unlike Pi and Tau — has **native subagents** (the task tool), **approval modes** and model **roles**. Every model goes through **Agentgateway** (`https://scarlet:9443/v1`).

## Layout

```text
omp/
├── Makefile                         build · lint · test · install-dry · install (deploy)
├── install.sh                       installs ONLY the config files below into ${PI_CODING_AGENT_DIR:-~/.omp/agent}
├── lib/                             install-lib.sh, merge_json.py (from _shared) · build-ca-bundle.mjs
├── tests/test_config.py             offline checks driven through the installed omp binary
└── home/.omp/agent/
    ├── AGENTS.md                    global instructions (router) — GENERATED (make build)
    ├── agents/*.md                  GENERATED: explorer reviewer planner developer sre architect security
    ├── guard/{guard.py,guardrails.json}   GENERATED: byte-identical copy of _shared/guardrails
    ├── guard/omp_guard.py           omp adapter: edit-mode shapes, python/notebook code
    ├── extensions/guardrails.ts     tool_call hook → omp_guard.py (fail-closed)
    ├── models.yml                   agentgateway provider (key from AGENTGATEWAY_API_KEY)
    ├── config.settings.json         keys install.sh applies with `omp config set` (model roles, approval mode)
    ├── omp-env.sh                   `omp` wrapper: 1Password key, CA bundle, leak guard, NO_PROXY
    └── prompts/*.md                 /review /plan /commit /test /explain /summarize /pr /scaffold /security-scan
                                     /iac-review /threat-model /adr /incident /cost-review /diagram /image
```

`_shared/tools/omp.yaml` is the build spec. Topic skills are not duplicated: omp reads `~/.agents/skills` (`skills.enableAgentsUser`, default on), installed by the [Codex](../codex) config.

## Verified behaviour (omp 18.18.3)

| Fact | How verified |
|---|---|
| `models.yml` lives in the agent dir; `providers.<name>.{baseUrl, api, apiKey, models[{id, name, contextWindow, maxTokens}]}` | `omp models agentgateway --json` against a scratch agent dir lists all 4 ids; the `contextWindow` override changes the output |
| `apiKey` is an **env-var name**; `$NAME`/`${NAME}` are sent literally (differs from Pi) | `omp token agentgateway` with a dummy env value |
| Unknown `models.yml` keys are silently ignored | a bogus key loaded without error — so only demonstrably applied keys are used |
| Model selectors are `agentgateway/<id>` (slashes kept) | `selector` field of `omp models --json` |
| Chat roles: default, smol, slow, vision, plan, commit, tiny, memory, task, advisor, widget | readable source `packages/tui/src/overlays/model-browser.ts` in the binary |
| `omp config set <key> <json>` merges into config.yml, keeps other keys, validates enums (not role names) | run in a scratch agent dir |
| `tools.approvalMode` ∈ always-ask, always-ask-cached, write, **yolo (default)** | `omp --help`, `omp config list --json`, enum error from `config set` |
| Subagents: `agents/*.md` frontmatter `name, description, tools, spawns, model, thinkingLevel, output` | `omp agents unpack --dir <scratch>` (bundled agents) |
| Global instructions: `~/.omp/agent/AGENTS.md`; **one** user-level context file wins by priority — omp's own (100) beats `~/.claude` (80), `~/.agents` (70), `~/.codex` (64–70), `~/.config/opencode` (55), `~/.copilot` (30) | readable source `capability/context-file.ts` (key `"user"`) + provider priority constants |
| `tool_call` extension event `{toolName, toolCallId, input}`; `{block, reason}` stops the call; handler error/timeout ⇒ block | readable source `ExtensionRunner.emitToolCall`; extension loads via `omp models -e` (negative control: a broken extension prints `Failed to load extension`) |
| Tool inputs: `bash.command`, `read.path`, `write.{path,content}`, `edit` modes `replace{path,old_string,new_string}` · `patch{path,edits[{rename?}]}` · `apply_patch/hashline/sloppy{input}` | edit-tool schema definitions in the binary |
| `NODE_EXTRA_CA_CERTS` honoured | `omp --help` environment section |
| No credentials stored in `agent.db` (`auth_credentials` empty) | read-only sqlite query, provider names only |

Not verifiable offline (sandbox blocks network and local listeners), so deliberately **not** used: per-model `api: anthropic-messages` overrides and Pi's `forceAdaptiveThinking` (absent from omp). Claude 5.5 is reached through `claude-sonnet-5` and the `openrouter/*` passthrough.

## Agents & models

| Agent | Model | Tools |
|---|---|---|
| router (main session) | `@default` → `claude-sonnet-5` | all, approval mode `write` |
| explorer | `@smol` → `deepseek-flash` | read-only + web |
| reviewer | `@smol` → `deepseek-flash` | read-only + bash (replaces omp's bundled `reviewer`) |
| planner | `@plan` → `openrouter/openai/gpt-6-sol` | read-only + web, spawns explorer |
| developer | `@task` → `claude-sonnet-5` | all |
| sre | `@task` → `claude-sonnet-5` | read + bash + web |
| architect | `@slow` → `openrouter/openai/gpt-6-sol` | read + edit/write + web |
| security | `openrouter/anthropic/claude-opus-5-5` | read + bash (scanners) + web |

Auxiliary roles (`commit`, `tiny` — titles/memory —, `memory`, `widget`, `advisor`, `vision`) also point at the gateway, so no call silently goes to a public provider.

## Security

- **Approval mode `write`** replaces omp's default `yolo`: reads and workspace writes run, everything else (shell included) asks.
- **Guardrails**: `extensions/guardrails.ts` runs `guard/omp_guard.py` (the shared guard + omp's edit shapes) on every tool call: deny → blocked, ask (`git push`, `reset --hard`, `stack rm`, destructive SQL) → confirm prompt, or blocked headless. A missing/failing guard throws, and omp blocks the call.
- **Key**: never stored. `models.yml` names `AGENTGATEWAY_API_KEY`; `omp-env.sh` fills it from `op read op://private/agent-gateway-api-key/password` per launch. It also **unsets any of `OPENAI_API_KEY`/`OPENROUTER_API_KEY`/`ANTHROPIC_API_KEY`/`ANTHROPIC_AUTH_TOKEN` that equal the gateway key** — your shell exports it under those names, and omp would otherwise enable those public providers with it (as Cline did with OpenAI).
- **TLS**: `install.sh` exports the OS trust store (public roots + your keychain-trusted gateway cert) to `~/.omp/agent/ca-bundle.pem` and verifies it against `scarlet:9443`; the wrapper sets `NODE_EXTRA_CA_CERTS` for omp only.
- **Proxy**: the wrapper adds `scarlet` to `NO_PROXY` (herdr panes can inherit a dead proxy).

## Install

```zsh
cd ~/AI_Workspace/Projects/agents-config/agent-configs/omp
make install-dry && make install
echo 'source ~/.omp/agent/omp-env.sh' >> ~/.dotfiles/config/zsh/.zshrc && exec zsh
omp -p --model agentgateway/deepseek-flash "Reply with: ok"
```

## Troubleshooting

| Symptom | Check |
|---|---|
| `401` / wrong provider | `whence -w omp` must say `function`; `omp models agentgateway` lists 4 models |
| TLS / `UNABLE_TO_VERIFY` | `make install` rebuilds and verifies `ca-bundle.pem` |
| `Extension … failed, blocking execution` | `python3` missing or `guard/` incomplete — reinstall (the block is the fail-closed design) |
| A model 404s on the gateway | the gateway lacks that route; change it in `models.yml` + `config.settings.json` |
| Duplicate instructions | shouldn't happen (single user-level context file); remove a project `AGENTS.md` copy if one exists |
