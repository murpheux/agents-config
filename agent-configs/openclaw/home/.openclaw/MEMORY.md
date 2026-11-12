# OpenClaw Setup Memory & Context

## Overview

This is OpenClaw 2026.9.2 configuration for Murpheux's multi-agent system running on a remote VM, with **agentgateway** (`10.10.2.80:9443`) as the primary LLM provider.

---

## Configuration Journey

### Initial Setup Issues (Fixed)

| Issue | Root Cause | Solution |
|-------|-----------|----------|
| Wrong filename | Using `config.json` instead of `openclaw.json` | ✅ Renamed to `openclaw.json` (standard JSON) |
| JSON comments | JSON doesn't allow comments in standard format | ✅ Removed all comments, kept clean JSON |
| Missing credentials | No `op.env` for credential management | ✅ Added `op.env` with 1Password references |
| Missing agent files | No agent system prompts | ✅ Created `agents/main/agent/system.md` |
| Unclear architecture | Didn't clarify agents/MCPs/guardrails | ✅ Documented: agents ✓, skills ✓, NOT MCPs ✗ |
| Model references | Listed models with undefined providers | ✅ Removed explicit model list, auto-discovery from gateway |
| Unrecognized keys | `isGateway` key not valid in 2026.9.2 | ✅ Removed deprecated keys |
| Missing model names | Models declared without `name` field | ✅ Added proper names for all models |
| Hostname resolution | DNS couldn't resolve `scarlet` | ✅ Changed to IP address `10.10.2.80` |
| Self-signed cert | Node.js rejecting agentgateway SSL cert | ✅ Set `NODE_TLS_REJECT_UNAUTHORIZED=0` in systemd |

---

## Current Architecture

### Gateway Flow

```
OpenClaw Agent
    ↓
Config: gateway.baseUrl = "https://10.10.2.80:9443/v1"
    ↓
agentgateway (OpenAI-compatible API)
    ↓
Model providers: Anthropic, DeepSeek, Google
```

### Agent Configuration

**File:** `~/.openclaw/openclaw.json`

```json
{
  "agents": {
    "defaults": {
      "workspace": "~/.openclaw/workspace",
      "model": {"primary": "deepseek/deepseek-flash"}
    },
    "entries": {
      "main": {
        "name": "main",
        "agentDir": "~/.openclaw/agents/main/agent",
        "model": {"primary": "deepseek/deepseek-flash"}
      }
    }
  },
  "gateway": {
    "provider": "agentgateway",
    "baseUrl": "https://10.10.2.80:9443/v1",
    "auth": {
      "token": {"id": "AGENTGATEWAY_API_KEY"}
    }
  },
  "models": {
    "providers": {
      "agentgateway": {
        "baseUrl": "https://10.10.2.80:9443/v1",
        "models": [
          {"id": "anthropic/claude-opus-5", "name": "Claude Opus 5"},
          {"id": "anthropic/claude-sonnet-4.5", "name": "Claude Sonnet 4.5"},
          {"id": "anthropic/claude-haiku-5.5", "name": "Claude Haiku 5.5"},
          {"id": "deepseek/deepseek-flash", "name": "DeepSeek Flash"},
          {"id": "deepseek/deepseek-reasoner", "name": "DeepSeek Reasoner"},
          {"id": "google/gemini-2.5-flash", "name": "Gemini 2.5 Flash"}
        ]
      }
    }
  }
}
```

### Systemd Service Configuration

**File:** `/home/murpheux/.config/systemd/user/openclaw-gateway.service`

```ini
[Service]
ExecStart=/usr/bin/node --max-old-space-size=2048 ... openclaw/dist/index.js gateway --port 18789
Environment="NODE_TLS_REJECT_UNAUTHORIZED=0"
Restart=always
RestartSec=5
OOMPolicy=continue
KillMode=control-group
```

**Commands:**
```bash
systemctl --user restart openclaw-gateway
journalctl --user -u openclaw-gateway -f
```

---

## Working Model IDs

The following model IDs are **confirmed working** via agentgateway:

- `anthropic/claude-opus-5` — Premium reasoning
- `anthropic/claude-sonnet-4.5` — Balanced capability
- `anthropic/claude-haiku-5.5` — Fast, lightweight
- `deepseek/deepseek-flash` — Fast + capable (current default)
- `deepseek/deepseek-reasoner` — Deep reasoning
- `google/gemini-2.5-flash` — Alternative provider

**DO NOT use:** `deepseek/deepseek-chat`, `anthropic/claude-3-*` (obsolete versions)

---

## Credentials & Secrets

### Credential Store Setup

All secrets use 1Password credential store pattern:

```json
"token": {
  "source": "store",
  "provider": "default",
  "id": "AGENTGATEWAY_API_KEY"
}
```

### How to Set Up

1. **Store the token in 1Password:**
   ```bash
   op secret set AGENTGATEWAY_API_KEY=<actual-token>
   ```

2. **Reference in `op.env`:**
   ```bash
   export AGENTGATEWAY_API_KEY="op://Personal/OpenClaw/agentgateway-token"
   ```

3. **Load when running (manual):**
   ```bash
   op run --env-file=op.env -- openclaw gateway run
   ```

4. **For systemd service:** Credentials are automatically resolved from the credential store by OpenClaw

---

## Important Notes

### SSL/TLS Certificate

- agentgateway uses a **self-signed certificate**
- OpenClaw must set `NODE_TLS_REJECT_UNAUTHORIZED=0` to accept it
- This is set in the systemd service via `Environment="NODE_TLS_REJECT_UNAUTHORIZED=0"`
- For production, use proper certificates or a CA

### Network Access

- OpenClaw remote VM must reach `10.10.2.80:9443`
- Use IP address, not hostname (DNS may not be configured)
- Firewall rules must allow HTTPS (port 9443) from VM to agentgateway host

### Model Resolution

- OpenClaw checks its **local bundled catalog** first
- Models must be declared in `models.providers.agentgateway.models`
- The model ID format must match exactly (case-sensitive)
- Invalid model IDs result in "Unknown model" errors

---

## Troubleshooting Checklist

### OpenClaw won't start

```bash
systemctl --user status openclaw-gateway
journalctl --user -u openclaw-gateway -f
```

Common issues:
- ❌ Port 18789 already in use → check `lsof -i :18789`
- ❌ Missing config file → verify `~/.openclaw/openclaw.json` exists
- ❌ Config validation error → run `openclaw config validate`

### Model "Unknown model" errors

1. ✅ Verify model ID in `models.providers.agentgateway.models`
2. ✅ Check exact spelling (case-sensitive)
3. ✅ Verify agentgateway is running: `curl -s https://10.10.2.80:9443/v1/models`
4. ✅ Check agentgateway logs for actual available models

### SSL certificate errors

```
DEPTH_ZERO_SELF_SIGNED_CERT or similar
```

**Solution:** Verify `NODE_TLS_REJECT_UNAUTHORIZED=0` in systemd service:
```bash
systemctl --user cat openclaw-gateway | grep NODE_TLS
systemctl --user daemon-reload
systemctl --user restart openclaw-gateway
```

### Network connection errors (EAI_AGAIN)

```
getaddrinfo EAI_AGAIN
```

**Solution:** Use IP address instead of hostname in gateway baseUrl:
```json
"baseUrl": "https://10.10.2.80:9443/v1"
```

### Agent can't call gateway

1. ✅ Verify gateway is reachable: `curl -k https://10.10.2.80:9443/v1/models`
2. ✅ Check firewall: `ssh _ai_daemon@scarlet "curl -k https://localhost:9443/v1/models"`
3. ✅ Verify agentgateway logs: `docker service logs <service-name>`

---

## Configuration Files

### Deployment Structure

Files deploy to `~/.openclaw/` (NOT to `~/.openclaw/workspace/`):

| File | Deployment Path | Purpose |
|------|-----------------|---------|
| `openclaw.json` | `~/.openclaw/openclaw.json` | Main configuration (JSON, no comments) |
| `USER.md` | `~/.openclaw/USER.md` | User profile (Murpheux, environment, tech stack) |
| `MEMORY.md` | `~/.openclaw/MEMORY.md` | This file — setup context and troubleshooting |
| `CONVENTIONS.md` | `~/.openclaw/CONVENTIONS.md` | Agent conventions and architecture |
| `op.env` | `~/.openclaw/op.env` | Credential store references (1Password) |
| `agents/main/agent/system.md` | `~/.openclaw/agents/main/agent/system.md` | Main agent system prompt |
| `skills/` | `~/.openclaw/skills/` | Shared skill library (on-demand loading) |
| `workspace/` | `~/.openclaw/workspace/` | **Agent state & persistent data (auto-created)** |

### Important Note

The `workspace/` directory is **separate** from configuration files:
- Configuration files go to `~/.openclaw/` (root level)
- Agent state/data goes to `~/.openclaw/workspace/` (subdirectory)
- Do NOT put config files in the workspace directory

---

## Deployment & Maintenance

### Installation

```bash
cd agent-configs/openclaw
DRY_RUN=1 ./install.sh    # Preview
./install.sh               # Install to ~/.openclaw/
```

### Build & Validate

```bash
make validate              # Check JSON syntax
make test                  # Test gateway connectivity
make schema                # View OpenClaw schema
make build                 # Full validation
```

### Updates

1. **Edit config:**
   ```bash
   vi ~/.openclaw/openclaw.json
   openclaw config validate
   ```

2. **Restart service:**
   ```bash
   systemctl --user restart openclaw-gateway
   ```

3. **Check logs:**
   ```bash
   journalctl --user -u openclaw-gateway -f
   ```

---

## Related Documentation

- **User Profile:** `USER.md` — Murpheux's environment, tech stack, preferences
- **Agent Conventions:** `CONVENTIONS.md` — Architecture, skills, channels, access control
- **Quick Start:** `../README.md` — Installation and verification
- **Makefile:** Build targets for validation and deployment

---

**Last Updated:** 2026-11-11  
**OpenClaw Version:** 2026.9.2  
**Configuration Status:** ✅ Production-ready (with self-signed cert workaround)  
**Primary Provider:** agentgateway (10.10.2.80:9443/v1)  
**Primary Model:** deepseek/deepseek-flash
