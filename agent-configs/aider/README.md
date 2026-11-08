# Aider — cost-aware configuration (Aider v0.86.x)

Aider has a single agent loop and **no subagents, hooks, MCP or custom slash commands** upstream (the `cecli` fork adds them). The OpenCode design is therefore mapped onto Aider's native levers: model tiers (main / weak / editor + architect mode), aliases and wrappers as the "router", `/load` command files as workflows, read-only skill files, and Aider's own safety options.

## Layout (mirrors `$HOME`)

```text
aider/
├── home/.aider.conf.yml              → ~/.aider.conf.yml          (models, cache, lint, git, safety)
├── home/.aider/CONVENTIONS.md        → full global instructions (read-only, prompt-cached)
├── home/.aider/model.settings.yml    → per-model edit format, editor/weak models, reasoning passthrough
├── home/.aider/model.metadata.json   → context limits + prices (placeholders) for gateway models
├── home/.aider/aider-aliases.sh      → ai, ai-ask, ai-cheap, ai-arch, ai-review, ai-sec, ai-sre
├── home/.aider/aider.op.env          → 1Password references (op run) — never secrets
├── home/.aider/commands/*.cmds       → /load workflows (review, security-review, plan, commit-check, skill-*)
├── home/.aider/skills/<id>/SKILL.md  → 20 on-demand skills (/read-only …)
├── home/.aider/bin/lint-go           → package-level Go lint wrapper
├── templates/.aiderignore            → copy into each repo
└── install.sh                        → backs up and installs (DRY_RUN=1 supported)
```

## Routing (tiers)

| Command | Mode / model | Use |
|---|---|---|
| `ai-ask` | ask · `openai/deepseek-flash` · effort low | questions, exploration, SIMPLE tasks |
| `ai-cheap` | code · deepseek-flash · small repo map | trivial edits |
| `ai` | code · `openai/claude-sonnet-5` · effort medium | NORMAL development |
| `ai-arch` | architect · `openrouter/openai/gpt-6-sol` plans → sonnet applies | COMPLEX / EXPERT |
| `ai-review` | ask · deepseek-flash · loads `review.cmds` | cheap diff review |
| `ai-sec` | ask · `openrouter/anthropic/claude-opus-5.5` · loads `security-review.cmds` | HIGH_RISK / security |
| `ai-sre` | ask · sonnet | diagnosis with `/run` of read-only commands |

The weak model (deepseek-flash) writes commit messages and summarises old chat history automatically.

## Cost controls

`cache-prompts` (caches system prompt, CONVENTIONS and repo map), `map-tokens: 1024`, `max-chat-history-tokens: 6000`, `cache-keepalive-pings: 0`, `auto-test: false` (failing test output is re-sent up to 3 times), reasoning effort only where it pays, and per-model `max_tokens` caps. Aider never enforces spend limits — put budgets on the LiteLLM virtual key.

## Security

- **Commits:** `git-commit-verify: true` — Aider's default is `--no-verify`, which would skip the ggshield pre-commit hook. `dirty-commits: false` so pre-existing work is never swept into a commit. Signing follows your git config (`commit.gpgsign`).
- **Shell:** `suggest-shell-commands: false`, `yes-always: false` — nothing runs without your explicit `/run` / confirmation.
- **Context:** `detect-urls: false` (no untrusted web content), gitignored files stay invisible, `.aiderignore` template for secret files.
- **Credentials:** injected by `op run --env-file ~/.aider/aider.op.env` per process. Never create `~/.env` for Aider (it auto-loads with override).
- **TLS:** `verify-ssl: true` with `SSL_CERT_FILE`/`REQUESTS_CA_BUNDLE` pointing at the full system bundle (install the home-lab CA into the OS store first).
- **Untrusted repos:** a repo's `.aider.conf.yml` or `.env` can set `lint-cmd`, `test-cmd`, `OPENAI_API_BASE` — inspect them before running Aider in unfamiliar code.

## Per-repo `test-cmd` examples (`<repo>/.aider.conf.yml`)

```yaml
read: ["~/.aider/CONVENTIONS.md"]          # lists replace the global one — repeat it
test-cmd: "go test ./... 2>&1 | tail -n 60"
# test-cmd: "dotnet test -v q --nologo 2>&1 | tail -n 60"
# test-cmd: "uv run pytest -q -x 2>&1 | tail -n 60"
# test-cmd: "npm test --silent 2>&1 | tail -n 60"
# test-cmd: "pwsh -NoProfile -Command Invoke-Pester -CI"
```

## Install

```bash
cd ~/agent-configs/aider && DRY_RUN=1 ./install.sh && ./install.sh
echo 'source ~/.aider/aider-aliases.sh' >> ~/.zshrc
```
