# Tau — Murpheux's Global Configuration

Configuration for [Tau](https://github.com/huggingface/tau) (`tau-ai` 0.4.x, docs at [twotimespi.dev](https://twotimespi.dev)), a Python, Pi-style single-agent coding harness. Like the [Pi](../pi) config, it is built only from mechanisms Tau documents (bundled docs under `tau_coding/data/docs/` and the installed source): **one model per session, no subagents, no permission rules**. Every model goes through **Agentgateway** (`https://scarlet:9443/v1`).

## Layout

```text
tau/
├── Makefile                        build · lint · test · install-dry · install (deploy)
├── install.sh                      installs ONLY the config files below into ${TAU_HOME:-~/.tau}
├── lib/                            install-lib.sh, merge_json.py (from _shared) · build-ca-bundle.mjs · scrub-credentials.py
├── tests/test_config.py            offline checks run with Tau's own interpreter
└── home/.tau/
    ├── AGENTS.md                   global instructions — GENERATED from the OpenCode baseline (make build)
    ├── catalog.toml                agentgateway provider overlay (key from AGENTGATEWAY_API_KEY, exact gateway model ids)
    ├── providers.fragment.json     merged into ~/.tau/providers.json: default provider = agentgateway
    ├── tau-env.sh                  `tau` wrapper: key from 1Password + OS-trust-store CA bundle, per process
    ├── extensions/guardrails.py    tool_call hook → shared guard (fail-closed)
    ├── guard/{guard.py,guardrails.json}   GENERATED: byte-identical copy of _shared/guardrails
    ├── skills/role-*/SKILL.md      GENERATED: developer, planner, sre, architect, reviewer, security
    └── prompts/*.md                /review /plan /commit /test /explain /summarize /pr /scaffold /security-scan
                                    /iac-review /threat-model /adr /incident /cost-review /diagram /image
```

`_shared/tools/tau.yaml` is the build spec; `make build` regenerates the GENERATED files. Topic skills (`golang`, `terraform`, `aws`, …) are **not** duplicated: Tau reads `~/.agents/skills`, which the [Codex](../codex) config installs.

## Fixes for the reported errors

| Error | Cause | Fix |
|---|---|---|
| `agentgateway … CERTIFICATE_VERIFY_FAILED: self-signed certificate` | Tau's httpx trusts **only** `SSL_CERT_FILE` (else `SSL_CERT_DIR`, else certifi) — never the macOS keychain. The shell's `SSL_CERT_FILE` is the public Mozilla bundle, which lacks the gateway's self-signed cert. | `install.sh` exports the **OS trust store** (public roots + the keychain-trusted gateway cert, same mechanism as the Cline CLI launcher) to `~/.tau/ca-bundle.pem` and verifies it against `scarlet:9443`; the `tau` wrapper sets it as `SSL_CERT_FILE` for Tau only. |
| `openai … unable to get local issuer certificate` | A bundle holding *only* the gateway cert breaks every public endpoint. | Same bundle — it contains the public roots too. |
| Session naming ran on OpenAI `gpt-5.4` | `providers.json` had `default_provider = "openai"`. | Fragment sets `default_provider = "agentgateway"`, so naming uses the gateway. |

## Secrets

- **No secrets in this folder.** Tau checks its plaintext `credentials.json` **before** a provider's `api_key_env` (`provider_config._api_key_from_provider`), so `catalog.toml` drops `credential_name` and the key comes only from `AGENTGATEWAY_API_KEY`.
- The `tau` wrapper reads that key from 1Password (`op read op://private/agent-gateway-api-key/password`) **at launch**, scoped to the Tau process — it survives key rotation and a 1Password that was locked when the shell started. Not `op run`: it pipes stdout through its masker and Tau's TUI loses the terminal.
- `install.sh` removes the leftover plaintext `agentgateway` entry from your live `~/.tau/credentials.json` (backed up first). Other entries — e.g. the built-in llama.cpp key that Tau manages via `/local` — are left alone.
- Runtime state (`credentials.json`, `sessions/`, `logs/`, `cache/`, `state/`, `models-store.json`, `providers.json`, installed extensions) is git-ignored and never installed.

## Guardrails

Tau has no allow/deny rules and its project trust only gates *loading* project inputs (`security.md`: "not a … shell … or exfiltration sandbox"). The documented gate is the `tool_call` extension hook: `extensions/guardrails.py` runs the repo's shared `guard.py` before every `bash`/`read`/`write`/`edit` call and blocks destructive, secret-reading and interactive commands and protected paths. Approval-required rules (`git push`, `git reset --hard`, `docker stack rm`, destructive SQL) are blocked too — Tau has no approval prompt — so the agent hands those commands to you. If the guard can't load, every guarded tool is blocked; Tau itself blocks a call whose hook raises.

## Models

| Tier | Gateway model | Use |
|---|---|---|
| cheap (default) | `deepseek-flash` | routing, Q&A, review, commit messages |
| workhorse | `claude-sonnet-5` | `/skill:role-developer`, `/skill:role-sre` |
| reasoning | `openrouter/openai/gpt-6-sol` | `/skill:role-planner`, `/skill:role-architect` |
| premium | `openrouter/anthropic/claude-opus-5-5` | `/skill:role-security` — HIGH_RISK only |

Tau sends model ids **verbatim** ("A model is the exact ID accepted by that provider"), so there is no `agentgateway/` prefix. Only models the gateway serves over chat completions are listed: Claude 5.5 needs the Messages API and `gpt-6.1-sol` the Responses API, so they're reached through `claude-sonnet-5` and the `openrouter/*` passthrough. Switch with `/model` or `tau --model <id>`.

## Install

```zsh
cd ~/AI_Workspace/Projects/agents-config/agent-configs/tau
make install-dry          # preview
make install              # lint + test + install (= make deploy)
echo 'source ~/.tau/tau-env.sh' >> ~/.dotfiles/config/zsh/.zshrc && exec zsh
tau --provider agentgateway --model deepseek-flash --print "Reply with: ok"
```

Optional: the herdr orchestration extension is third-party code — review it, then `tau install git:github.com/rian-dolphin/tau-herdr`.

## Troubleshooting

| Symptom | Check |
|---|---|
| `CERTIFICATE_VERIFY_FAILED` | Running plain `command tau` (bypasses the wrapper)? `whence -w tau` must say `function`. Rebuild the bundle: `make install`. |
| `Missing provider API key. Set AGENTGATEWAY_API_KEY` | 1Password locked — unlock and re-run; or `credentials.json` still has an entry that shadows it (re-run `make install`). |
| `401` from the gateway | The 1Password item doesn't hold the key Agentgateway currently accepts. |
| Global instructions appear twice | Tau also loads `~/.agents/AGENTS.md` (yours links to an older Copilot/OpenCode copy) — remove or retarget it if it isn't meant for Tau. |
| `Blocked by guardrails …` | Intentional; adjust `_shared/guardrails/guardrails.json`, then `make build` (never patch the copy here). |
