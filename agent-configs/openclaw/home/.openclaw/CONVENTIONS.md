# OpenClaw Agent Conventions

> **OpenClaw note:** Configuration lives at `~/.openclaw/openclaw.json` (JSON5 format). This `CONVENTIONS.md` is supplementary documentation. A project `.openclaw/CONVENTIONS.md` *augments* it with project-specific guidance. OpenClaw agents (2026.9.2) run in a distributed workspace with **agentgateway** as the default provider.

---

## 1. About This Setup

OpenClaw (2026.9.2) is a multi-agent AI platform with:

- **Configuration-driven agents** — defined in `~/.openclaw/openclaw.json` (JSON5 format)
- **Gateway integration** — **agentgateway** (`https://scarlet:9443/v1`) as the primary provider
- **Multi-model support** — Anthropic Claude, DeepSeek, Google Gemini via agentgateway
- **Multi-channel** — Slack, Discord, Telegram, WhatsApp integrations
- **Workspace isolation** — per-agent state and session data
- **Skills system** — agents load repeatable procedures on-demand
- **Credential store integration** — secrets from 1Password, OS credential manager, etc.
- **Access control** — allowlists and mention rules (not separate hook files)

---

## 2. Gateway & Provider Configuration

### Default Provider: Agentgateway

The primary provider is configured as **agentgateway**, running at `https://scarlet:9443/v1`:

```json
"gateway": {
  "mode": "remote",
  "provider": "agentgateway",
  "baseUrl": "https://scarlet:9443/v1",
  "auth": {
    "mode": "token",
    "token": {
      "source": "store",
      "provider": "default",
      "id": "AGENTGATEWAY_TOKEN"
    }
  }
}
```

**To use:** retrieve `AGENTGATEWAY_TOKEN` from your credential store and configure it before starting agents.

### Model Tiers

| Tier | Models | Use case |
|---|---|---|
| Cheap (router/explorer) | `deepseek/deepseek-flash` | Quick answers, exploration, review |
| Workhorse (developer/sre) | `anthropic/claude-sonnet-4.5` | Implementation, diagnostics |
| Premium (architect/security) | `anthropic/claude-opus-5` | Design, threat modeling, security review |
| Reasoning | `deepseek/deepseek-reasoner` | Complex problem-solving |

All models are accessed through **agentgateway** unless an agent specifies a direct provider override.

---

## 3. Agent Architecture

### Configuration Structure

OpenClaw uses a **two-bucket model** in `openclaw.json`:

1. **Root siblings** — infrastructure and cross-agent defaults (gateway, models, channels, plugins, etc.)
2. **`agents.defaults`** — agent-loop behavior (workspace, auth, available models, default model)
3. **`agents.entries`** — per-agent overrides (workspace, identity, model selection)

### Agent Defaults

Every agent inherits from `agents.defaults`:

```json5
"agents": {
  "defaults": {
    // Workspace for persistent state
    "workspace": "~/.openclaw/workspace",
    
    // Auth inheritance: all agents use 'main' agent's credentials
    "authInheritance": {
      "agentId": "main"
    },
    
    // Available models (all agents can use these)
    "models": {
      "anthropic/claude-opus-5": {},
      "anthropic/claude-sonnet-4.5": {},
      "deepseek/deepseek-flash": {},
      "deepseek/deepseek-reasoner": {}
    },
    
    // Default model for this agent
    "model": {
      "primary": "deepseek/deepseek-flash"
    },
    
    // Thinking mode for reasoning models
    "thinkingDefault": "low"
  }
}
```

### Creating a New Agent

Add to `agents.entries` to override defaults:

```json5
"agents": {
  "entries": {
    "specialist": {
      "name": "specialist",
      "workspace": "~/.openclaw/workspace",
      
      // Agent system prompt and definitions
      "agentDir": "~/.openclaw/agents/specialist/agent",
      
      // Agent identity (name, metadata)
      "identity": {
        "name": "specialist"
      },
      
      // Override default model for this agent
      "model": {
        "primary": "anthropic/claude-opus-5"
      }
    }
  }
}
```

**Fields:**
- **workspace** — directory for agent state (can be shared or per-agent)
- **agentDir** — location of agent system prompt (`~/.openclaw/agents/<name>/agent/system.md`)
- **identity** — agent name and metadata
- **model** — model selection (overrides defaults)

---

## 4. Workspace Layout

```
~/.openclaw/
  config.json                          # Main configuration (this file's location)
  workspace/                           # Shared workspace root
    <project-name>/                    # Project-specific workspace
      state.json
      memory/
        conversations/
      artifacts/
  agents/
    main/agent/                        # Main agent definition
    <agent-name>/agent/                # Per-agent definitions
      system.md                        # Agent system prompt
      conventions.md                   # Agent-specific conventions
  skills/                              # Shared skill library
    <skill-id>/
      SKILL.md
  commands/                            # Custom commands
```

---

## 5. Skills System

Skills teach agents repeatable procedures and domain knowledge:

**Location:** `~/.openclaw/skills/<skill-id>/SKILL.md`

**Example skill structure:**
```
~/.openclaw/skills/
  golang/
    SKILL.md          # Go development skill
  terraform/
    SKILL.md          # Infrastructure-as-Code
  security/
    SKILL.md          # Security review guidance
```

**How agents use skills:**
- Agents load skills on-demand based on context
- Ask the agent to use a skill with `/skill <id>` or mention it in a message
- Skills can include tools, workflows, and domain-specific knowledge

**Creating a skill:**
See `~/.openclaw/skills/` and add a `<skill-id>/SKILL.md` file with:
- Frontmatter: `name` and `description`
- Body: detailed guidance and procedures

---

## 6. Secrets & Credential Management

> **Never inline secrets in openclaw.json.**

Use credential stores for all sensitive values:

```json5
"token": {
  "source": "store",
  "provider": "default",
  "id": "AGENTGATEWAY_TOKEN"
}
```

**Supported credential stores:**
- **1Password** — via `op` CLI (recommended)
- **OS credential manager** — macOS Keychain, Windows Credential Manager, Linux secret-service
- **Environment variables** — as fallback (development only, not recommended)

**Setup:**
1. Store credential in 1Password: `op secret set AGENTGATEWAY_TOKEN=<token>`
2. Reference in config with credential store pattern (shown above)
3. Run OpenClaw with credentials: `op run --env-file=op.env -- openclaw gateway run`

---

## 6. Channels & Access Control (Guardrails)

OpenClaw access control is **configuration-driven** (not separate hook files like Claude Code).

### Channel Configuration

```json5
"channels": {
  "slack": {
    "enabled": true,
    "botToken": {"source": "store", "id": "SLACK_BOT_TOKEN"},
    "appToken": {"source": "store", "id": "SLACK_APP_TOKEN"},
    
    // ─── ACCESS CONTROL ───
    "dmPolicy": "allowlist",           // DM policy
    "groupPolicy": "allowlist",        // Group chat policy
    "allowFrom": ["U0BUWDYBEDD"],     // Allowed user IDs
    
    // ─── MENTION RULES ───
    "groups": {
      "*": {
        "requireMention": true         // Require @bot mention
      }
    }
  },
  
  "discord": {
    "enabled": false,
    "token": {"source": "store", "id": "DISCORD_BOT_TOKEN"},
    "dmPolicy": "allowlist",
    "allowFrom": ["840242350344634419"]
  },
  
  "telegram": {
    "enabled": false,
    "botToken": {"source": "store", "id": "TELEGRAM_BOT_TOKEN"},
    "allowFrom": ["+15555550123"]
  }
}
```

### Guardrails (Access Control Rules)

OpenClaw enforces guardrails **inline in openclaw.json**, not via separate guard.py files:

| Rule | Location | Purpose |
|------|----------|---------|
| **Allowlists** | `channels.<ch>.allowFrom` | Explicit user/number whitelist |
| **Mention rules** | `channels.<ch>.groups.*.requireMention` | Require @mention in groups |
| **Session isolation** | Built-in | DMs vs. groups (isolated sessions) |
| **Sandbox mode** | `sandbox.mode` | Full access or sandboxed execution |
| **Remote approvals** | `remoteActionApprovals` | Approval required for sensitive actions |

**Key difference from Claude Code:** No separate `guardrails.json` or `guard.py` files. All access control is in `openclaw.json`.

### Plugins & Integrations

Plugins enable optional integrations:

```json5
"plugins": {
  "entries": {
    "anthropic": {"enabled": true},
    "deepseek": {"enabled": true},
    "github": {"enabled": false},
    "slack": {"enabled": false}
  }
}
```

Enable by setting `"enabled": true` and providing credentials via credential store.

---

## 7. Agent Roles & Models

Define agents to match the roles from your project's CLAUDE.md or agent specification. Examples:

| Agent | Model | Workspace | Purpose |
|---|---|---|---|
| `main` | `deepseek-flash` | `~/.openclaw/workspace` | Router, quick answers |
| `developer` | `claude-sonnet-4.5` | `~/.openclaw/workspace` | Code implementation |
| `architect` | `claude-opus-5` | `~/.openclaw/workspace` | Design & architecture |
| `security` | `claude-opus-5` | `~/.openclaw/workspace` | Security review |

Each agent inherits conventions from `~/.openclaw/CONVENTIONS.md` and can add project-specific overrides via `.openclaw/CONVENTIONS.md` in the project root.

---

## 7. Configuration Files & NOT Needed

### Required Files

- **`~/.openclaw/openclaw.json`** (JSON5 format) — Main configuration
- **Agent definitions** — `~/.openclaw/agents/<name>/agent/system.md` (one per agent)
- **Skills** — `~/.openclaw/skills/<id>/SKILL.md` (optional, as needed)

### NOT Needed (Unlike Claude Code)

❌ **MCPs (Model Context Protocol servers)** — OpenClaw uses Skills instead  
❌ **Guard hooks** (`guardrails.json`, `guard.py`) — Access control is inline in `openclaw.json`  
❌ **Agent specs** (`.md` files for agent routing) — Agents defined in config only  

**Why the difference?**
- OpenClaw is configuration-driven; Claude Code is file/hook-driven
- Guardrails are access control rules in channels/config, not separate enforcement files
- Skills replace MCP servers for agent knowledge

---

## 8. Configuration Validation

OpenClaw validates `openclaw.json` at startup:

- ✅ JSON5 syntax conformance (comments and trailing commas allowed)
- ✅ Schema validation (required fields, types)
- ✅ Auth inheritance chains (no circular references)
- ✅ Workspace directories (exist or are creatable)
- ✅ No inline secrets (detects plaintext tokens, keys)
- ✅ Provider availability (gateway reachable)

**View schema:**
```bash
openclaw config schema
openclaw config schema <path>  # e.g., agents.defaults.models
```

If validation fails, `openclaw gateway run` exits with code 78. Check the error log and fix before restarting.

---

## 9. Pre-commit Guardrails

Before committing config changes:

```bash
ggshield secret scan ~/.openclaw/config.json
git status ~/.openclaw/
```

- ✅ Never commit plaintext tokens, API keys, or credentials
- ✅ Always use credential store references
- ✅ Mark sensitive files in `.gitignore` if storing locally (e.g., test configs)

---

## 10. Troubleshooting

### Agent won't start

1. **Check workspace directory exists:**
   ```bash
   ls -la ~/.openclaw/workspace
   mkdir -p ~/.openclaw/workspace  # Create if missing
   ```

2. **Verify gateway connectivity:**
   ```bash
   curl -I https://scarlet:9443/v1/models
   ```

3. **Confirm credentials:**
   ```bash
   op read "op://Personal/AGENTGATEWAY_TOKEN/credential"  # Test access
   ```

4. **Validate config:**
   ```bash
   python3 -m json.tool ~/.openclaw/config.json > /dev/null
   ```

### Models not available

- Check `models.providers.<provider>` is configured with correct baseUrl and apiKey
- Verify gateway auth token is valid and has model access
- List available models: `curl https://scarlet:9443/v1/models -H "Authorization: Bearer $TOKEN"`

### Workspace permission errors

- Ensure `~/.openclaw/workspace` is writable: `chmod 700 ~/.openclaw/workspace`
- Confirm agent `agentDir` paths exist or are creatable

---

## 11. Next Steps

1. **Configure credentials:** Store `AGENTGATEWAY_TOKEN` in your credential manager
2. **Create workspace:** `mkdir -p ~/.openclaw/workspace`
3. **Add agents:** Define additional agents in `agents.entries` as needed
4. **Test connectivity:** Run a simple command with the main agent
5. **Enable plugins:** Uncomment Slack/Discord/Telegram config and add credentials if needed

---

**Last updated:** 2026-11-11  
**Configuration version:** 1.0.0
