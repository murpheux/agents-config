# OpenClaw Agent Configuration

OpenClaw is a multi-agent orchestration platform with **agentgateway** as the default provider.

## Quick Start

```bash
cd openclaw
DRY_RUN=1 ./install.sh    # Preview installation
./install.sh               # Install configuration to ~/.openclaw/
```

The installer:
- ✅ Creates `~/.openclaw/` directory structure
- ✅ Installs `openclaw.json` with agentgateway as default provider
- ✅ Creates workspace directories for agent state
- ✅ Creates agents and skills directories
- ✅ Backs up any existing config to `~/.agent-config-backups/openclaw/`

## Configuration File

**Location:** `~/.openclaw/openclaw.json`  
**Format:** JSON5 (comments and trailing commas allowed)

### Gateway: Agentgateway

Default provider configured at `https://scarlet:9443/v1`:

```json5
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

**Setup credential:**
```bash
op secret set AGENTGATEWAY_TOKEN=<your-token>
```

### Model Tiers

| Role | Default Model | Provider |
|---|---|---|
| Router / Explorer | `deepseek/deepseek-flash` | agentgateway |
| Developer / SRE | `anthropic/claude-sonnet-4.5` | agentgateway |
| Architect / Security | `anthropic/claude-opus-5` | agentgateway |

All models are accessed through **agentgateway** unless overridden per-agent.

### Agent Structure

Agents are defined in `openclaw.json`:

```json5
"agents": {
  "defaults": {
    // Shared defaults for all agents
    "workspace": "~/.openclaw/workspace",
    "model": {"primary": "deepseek/deepseek-flash"},
    "models": {
      "anthropic/claude-opus-5": {},
      "anthropic/claude-sonnet-4.5": {},
      "deepseek/deepseek-flash": {},
      "deepseek/deepseek-reasoner": {}
    }
  },
  "entries": {
    "main": {
      "name": "main",
      "workspace": "~/.openclaw/workspace",
      "agentDir": "~/.openclaw/agents/main/agent",
      "model": {"primary": "deepseek/deepseek-flash"}
    }
  }
}
```

**To add more agents:**
1. Add entry to `agents.entries`
2. Create agent system prompt at `~/.openclaw/agents/<name>/agent/system.md`
3. Override defaults (workspace, model) as needed

### Skills System (NOT MCPs)

OpenClaw uses **Skills** instead of MCP servers:

- **Location:** `~/.openclaw/skills/<skill-id>/SKILL.md`
- **Format:** Markdown with YAML frontmatter
- **Usage:** Agents load on-demand based on context

Example:
```
~/.openclaw/skills/
  golang/SKILL.md        # Go development
  terraform/SKILL.md     # Infrastructure-as-Code
  security/SKILL.md      # Security review
```

### Access Control (NOT separate files)

**Guardrails are inline!** No `guardrails.json` or `guard.py` needed:

```json5
"channels": {
  "slack": {
    "enabled": false,
    "allowFrom": ["U0BUWDYBEDD"],      // Allowlist
    "groups": {"*": {"requireMention": true}}  // Require @mention
  }
}
```

This is the OpenClaw way (unlike Claude Code's separate guard hooks).

## Files Created

| File | Purpose |
|---|---|
| `home/.openclaw/openclaw.json` | Main configuration (JSON5 format) |
| `home/.openclaw/CONVENTIONS.md` | Agent conventions and guidelines |
| `home/.openclaw/agents/main/agent/system.md` | Main agent system prompt |
| `install.sh` | Installer script with backup support |
| `op.env` | Credential store configuration |
| `Makefile` | Build, validate, test targets |
| `README.md` | This file |

## Workspace Structure

**Important: Configuration files deploy to `~/.openclaw/` root, NOT workspace:**

```
~/.openclaw/
  ├── openclaw.json              Configuration (JSON, no comments)
  ├── CONVENTIONS.md             Agent conventions & architecture
  ├── USER.md                    User profile & environment
  ├── MEMORY.md                  Setup context & troubleshooting
  ├── op.env                     Credential store references
  │
  ├── agents/
  │   └── main/agent/
  │       └── system.md          Main agent system prompt
  │
  ├── skills/                    Shared skill library
  │   └── (add skills as needed)
  │
  └── workspace/                 ← Agent state & data (auto-created, NOT configs)
      ├── state.json
      ├── memory/
      │   └── conversations/
      └── artifacts/
```

**Note:** Configuration files (openclaw.json, USER.md, MEMORY.md, etc.) go to `~/.openclaw/`.
The `workspace/` subdirectory is for agent runtime state and persistent data only.

## Verification

After installation, test the setup:

1. **Validate JSON5 syntax:**
   ```bash
   python3 -m json.tool ~/.openclaw/openclaw.json > /dev/null
   echo "✓ Syntax valid"
   ```

2. **Verify gateway connectivity:**
   ```bash
   TOKEN=$(op read op://Personal/AGENTGATEWAY_TOKEN/credential)
   curl -I https://scarlet:9443/v1/models \
     -H "Authorization: Bearer $TOKEN"
   ```

3. **Check schema:**
   ```bash
   op run --env-file=op.env -- openclaw config schema
   ```

4. **Test agents directory:**
   ```bash
   ls -la ~/.openclaw/agents/main/agent/
   ```

## Updating Configuration

Edit `~/.openclaw/openclaw.json` to:
- Add new agents in `agents.entries`
- Override model per agent
- Enable/configure channels (Slack, Discord, Telegram, WhatsApp)
- Add skills at `~/.openclaw/skills/<id>/SKILL.md`
- Update workspace paths
- Modify credential store references

Changes take effect when OpenClaw restarts (`openclaw gateway run`).

## Secrets & Security

**Important:** Never inline secrets in `openclaw.json`.

All credentials use the credential store pattern:

```json5
"token": {
  "source": "store",
  "provider": "default",
  "id": "KEY_NAME"
}
```

**Before committing:**
```bash
ggshield secret scan ~/.openclaw/openclaw.json
git status ~/.openclaw/
```

Load credentials with:
```bash
op run --env-file=op.env -- openclaw gateway run
```

## Documentation

- **Conventions:** `~/.openclaw/CONVENTIONS.md`
- **Gateway Info:** `https://scarlet:9443/v1` (requires auth token)

## Troubleshooting

**Gateway unreachable:**
```bash
ping -c 1 scarlet
ssh -o ConnectTimeout=5 _ai_daemon@scarlet "echo OK"
```

**Model not available:**
Check `models.providers.agentgateway` is configured with correct baseUrl and token.

**Workspace issues:**
```bash
ls -la ~/.openclaw/workspace
mkdir -p ~/.openclaw/workspace
chmod 700 ~/.openclaw/workspace
```

---

**Version:** 1.0.0  
**Provider:** agentgateway (`https://scarlet:9443/v1`)  
**Last updated:** 2026-11-11
