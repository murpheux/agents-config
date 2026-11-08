# Claude Code — cost-aware multi-agent configuration (v2.1.28x)

The closest match to the OpenCode design of all six tools. The **main session runs as a custom `router` agent on Haiku** (`"agent": "router"`), and the guard hook makes it read-only, so it has to delegate to specialist subagents on the right model tier.

## Layout (mirrors `$HOME`)

```text
claude-code/
├── home/.claude/settings.json          agent=router, permissions, guard hook, sandbox, env, status line
├── home/.claude/settings.gateway.json  optional Agentgateway overlay (./install.sh --gateway)
├── home/.claude/CLAUDE.md              global memory (full instructions, Claude-specific §13/§14/§17)
├── home/.claude/agents/                router, explore (overrides built-in Explore), reviewer, planner,
│                                       developer, sre, architect, security
├── home/.claude/commands/              16 slash commands (/review /commit /plan /test /explain /summarize /pr
│                                       /scaffold /security-scan /iac-review /threat-model /write-adr /incident
│                                       /cost-review /diagram /image)
├── home/.claude/skills/                20 skills (Agent Skills spec)
├── home/.claude/hooks/                 guard.py + guardrails.json (shared with all tools)
├── home/.claude/statusline.py          model · effort · $ · context %
├── mcp/add-mcp-servers.sh              claude mcp add-json --scope user (github, context7, mslearn, awsdocs, terraform)
└── install.sh
```

## Tiers

| Agent | Model · effort | Notes |
|---|---|---|
| router (main session) | haiku | reads/searches, answers SIMPLE, delegates everything else |
| Explore | haiku | overrides the built-in, which would otherwise inherit the main model |
| reviewer | haiku | `omitClaudeMd: true` keeps it small |
| developer, sre | sonnet · medium | workhorse |
| planner | opus · medium | `permissionMode: plan` (read-only) |
| architect | opus · high | design, ADRs, diagrams |
| security | opus · high | premium, HIGH_RISK + security only |

Other cost levers: `autoCompactWindow: 200000`, `BASH_MAX_OUTPUT_LENGTH=20000`, subagent depth 2 and 4 concurrent, cheap `model: haiku` on `/commit /explain /summarize /pr`, skills loaded on demand, and a status line showing $ and context %.

## Guardrails (defence in depth)

1. `permissions.deny` — always wins, even in bypass mode: push, destroy, disk tools, secret-printing commands, secret files (`~/.ssh/id_*`, `.env`, `*.tfstate`, keys, cloud creds, AI-tool credential files), `.git/**` edits, 1Password MCP.
2. **Guard hook** (PreToolUse on Bash/PowerShell/Read/Edit/Write/…): regex rules for what prefix rules miss (`git -C x push -f`, `curl | sh`, `.env.*` with example exceptions, interactive programs) and the **router gate** (main thread may only run read-only commands).
3. **Sandbox**: writes confined to the project, network to allow-listed registries/docs (a new domain prompts); cloud/cluster CLIs are excluded and go through normal prompts.
4. `CLAUDE_CODE_SUBPROCESS_ENV_SCRUB=1` strips credentials from Bash/hook/MCP environments; `DISABLE_TELEMETRY=1`.
5. MCP secrets are `${VAR}` references expanded at runtime; the gateway key comes from `apiKeyHelper` (`op read` run by Claude Code, not the model).

## Recommended from awesome-claude-code

- **Adopted natively:** cost-tiered agents and a router (the *compass* idea, without its `~/.claude` symlink installer), destructive-command guard (*claude-code-safety-net* idea → `guard.py`), status line with cost (*ccstatusline* idea → `statusline.py`).
- **Install:** `ccusage` (cost reports), Trail of Bits `skills` (CodeQL/Semgrep security skills), `antonbabenko/terraform-skill`, the official draw.io plugin (`jgraph/drawio-mcp`), Anthropic's `security-guidance` plugin, `dagger/container-use` for isolated parallel work.

## Install

```bash
cd ~/agent-configs/claude-code && DRY_RUN=1 ./install.sh && ./install.sh     # add --gateway for Agentgateway
./mcp/add-mcp-servers.sh
```
