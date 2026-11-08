# OpenAI Codex CLI — cost-aware configuration (rust-v0.157.x)

Codex now has everything the OpenCode design needs natively: custom subagents (`~/.codex/agents/*.toml`), profiles as files, skills, stable hooks, Starlark exec-policy rules, an OS sandbox and secret-filtering of the shell environment. Custom prompts were **removed in 0.118**, so the 16 slash commands are shipped as explicit-only workflow skills (`$review`, `$plan`, …).

## Layout (mirrors `$HOME`)

```text
codex/
├── home/.codex/config.toml             models, subagent defaults, sandbox, env filtering, hook, providers, MCP
├── home/.codex/{cheap,deep,audit,gateway}.config.toml   tier profiles (codex --profile <name>)
├── home/.codex/AGENTS.md               global instructions incl. the router policy (33 KB; cap raised to 64 KiB)
├── home/.codex/agents/*.toml           explorer, reviewer, planner, developer, sre, architect, security
├── home/.codex/rules/guardrails.rules  37 forbidden/prompt exec-policy rules (no allow rules — allow = unsandboxed)
├── home/.codex/hooks/{guard.py,guardrails.json}   PreToolUse guard (shared with every other tool)
├── home/.agents/skills/                20 portable skills (Codex's supported user skills dir; also read by Copilot CLI / Cline next)
├── home/.codex/skills/                 16 workflow skills (explicit invocation only; Codex-only dir so other tools don't load them)
└── install.sh
```

## Tiers

| Role | Model · effort | Why |
|---|---|---|
| main thread / router | `gpt-6-sol` · medium | reliable orchestration and NORMAL work |
| explorer, reviewer, unnamed helpers | `gpt-6-luna` · medium/high | ~20× cheaper than Sol |
| planner, developer, sre | `gpt-6-sol` · medium | workhorse |
| architect | `gpt-6-sol` · xhigh | hard design only |
| security | `gpt-6-astra` · medium | premium, HIGH_RISK only |
| `--profile cheap` | Luna · high | Q&A / triage sessions |
| `--profile deep` | Sol · xhigh | hard debugging/design sessions |
| `--profile audit` | Astra, read-only, approvals never | security reviews |
| `--profile gateway` | via Agentgateway (LiteLLM `/v1/responses`) | when not using `codex login` |

Other cost levers: `model_verbosity = "low"`, `review_model = gpt-6-luna`, `tool_output_token_limit = 12000`, `model_auto_compact_token_limit = 180000`, `web_search = "cached"`, max 4 concurrent subagents at depth 1, and a stable AGENTS.md prefix (cached input is 10× cheaper).

## Guardrails (defence in depth)

1. **Sandbox** `workspace-write`, network off by default (the `sre` agent enables network); `.git/.codex/.agents` stay read-only.
2. **Exec-policy rules** — `forbidden` for disk wipes, root/home deletes, force-push, destroy, bucket deletion, secret printing; `prompt` for push, apply, cluster/swarm mutations, opaque `bash -c` scripts.
3. **Guard hook** — the shared `guard.py` catches what argv prefixes miss (`git push origin -f`, pipes into interpreters, `.env` access, interactive programs, patches touching secret files).
4. **Environment filtering** — `*KEY*/*SECRET*/*TOKEN*` defaults plus 1Password, PAT, gateway and AWS secret variables are stripped from commands.
5. **Approvals** `on-request`; gateway credentials come from `op read` executed by Codex itself (never shown to the model).

## Install

```bash
cd ~/agent-configs/codex && DRY_RUN=1 ./install.sh && ./install.sh
codex --strict-config   # then /hooks → trust the guard
```
