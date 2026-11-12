# OpenClaw User Profile

## Identity

- **Name:** Murpheux Melony
- **Pronouns:** he/him/his
- **Title:** Senior Systems Architect & SRE
- **Location:** Calgary, Alberta, Canada (MT/MDT timezone)
- **Email:** murpheux@home.network (internal)

---

## Primary Development Host

- **Hostname:** medusa / softcraftmedusa
- **OS:** macOS Tahoe
- **IP Address:** 10.10.2.100
- **Role:** Main development workstation

---

## Infrastructure & Network

### Home Network

- **Subnet:** 10.10.2.0/24
- **Router:** 10.10.2.1

### Docker Swarm Cluster

| Host | Hostname | IP Address | Role | OS |
|------|----------|------------|------|-----|
| scarlet | softcraftscarlet | 10.10.2.80 | Swarm Manager | Arch Linux |
| gru | softcraftgru | 10.10.2.84 | Swarm Worker 1 | Ubuntu |
| cass | softcraftcassandra | 10.10.2.110 | Swarm Worker 2 | Manjaro Linux |

### Remote Services

- **agentgateway:** `https://10.10.2.80:9443/v1` (primary LLM provider)
- **Prometheus:** `http://10.10.2.80:9090`
- **Grafana:** `http://10.10.2.80:3000`
- **Elasticsearch/Kibana:** `http://10.10.2.80:5601`
- **MinIO:** `http://10.10.2.80:9001`

---

## Primary Tech Stack

### Cloud Platforms

- AWS (primary) — access via `op plugin run -- aws`
- Azure, GCP, DigitalOcean, Linode (secondary)

### Infrastructure as Code

- **Terraform / OpenTofu** — cloud provisioning
- **Ansible** — server-state configuration
- **Docker Compose / Swarm** — container orchestration

### Programming Languages

| Language | Version | Notes |
|----------|---------|-------|
| Go | 1.26 | Idiomatic, stdlib-first |
| Python | 3.12 | Type-annotated, pydantic, ruff |
| TypeScript | Latest | Strict mode, biome |
| C# / .NET | 10.0.300 | Nullable enabled, async/await |
| Node.js | v22 | TypeScript strict |
| Bash / Zsh | Latest | Primary shell (macOS) |

### Key Tools

- **1Password CLI** — credential management (`op` plugin)
- **GitHub CLI** — repo operations (`gh`)
- **Docker / Podman** — containerization
- **SSH Access:** User `_ai_daemon` on all Swarm nodes
- **Secrets Scanning:** `ggshield` pre-commit hooks

---

## OpenClaw Setup

### Configuration Location

**All configuration files deploy to `~/.openclaw/` (NOT workspace):**

```
~/.openclaw/
├── openclaw.json              ← Main config
├── CONVENTIONS.md             ← Architecture docs
├── USER.md                    ← User profile (this file)
├── MEMORY.md                  ← Setup context
├── op.env                     ← Credential references
├── agents/
│   └── main/agent/
│       └── system.md
├── skills/                    ← Skill library
└── workspace/                 ← Agent state (auto-created, NOT configs)
```

### Gateway Configuration

- **Provider:** agentgateway (https://10.10.2.80:9443/v1)
- **Auth:** Token-based (AGENTGATEWAY_API_KEY via 1Password)
- **SSL Note:** Self-signed cert (NODE_TLS_REJECT_UNAUTHORIZED=0 in systemd service)

### Agent Configuration

- **Main Agent:** `main` — router, quick answers (default: deepseek-flash)
- **Workspace:** `~/.openclaw/workspace` (agent state & persistent data)
- **Credentials:** 1Password credential store (not inline)

### Available Models (via agentgateway)

- **Fast/Cheap:** `deepseek/deepseek-flash`
- **Capable:** `anthropic/claude-sonnet-4.5`, `anthropic/claude-haiku-5.5`
- **Premium:** `anthropic/claude-opus-5`
- **Reasoning:** `deepseek/deepseek-reasoner`
- **Alternative:** `google/gemini-2.5-flash`

---

## Workflow Preferences

### Git & Commits

- **Signed commits:** `git commit -S -m "..."`
- **Style:** Conventional commits with semantic prefixes
- **Merge strategy:** Squash-merge PRs preferred
- **Branch naming:** `kebab-case` (e.g., `feat/add-s3-backend`)

### Code Quality

- **Pre-commit hooks:** `ggshield secret scan` (required)
- **Linting:** shellcheck (bash), ruff (Python), biome (TS)
- **Testing:** Mandatory before commit
- **Security:** Never inline secrets; always use credential store

### Shell & Interactive

- **Default shell:** zsh
- **Default browser:** Safari (Brave for Chrome-based)
- **Clipboard:** `pbcopy` (macOS)
- **Scripting language:** bash/zsh for Linux/macOS (NOT PowerShell for Unix)

---

## Context & Operating Guidelines

### Decision Protocol

| Situation | Action |
|-----------|--------|
| Task clear & reversible | Proceed — explain what's happening |
| Task clear but **destructive** | **Stop and ask first** |
| Task ambiguous | State assumption, proceed (or ask if complex) |
| Task needs secret/credential | **Never guess — ask for it** |
| Affects production/shared system | **Confirm before executing** |

### Destructive Operations (Always Ask First)

- `terraform destroy` / `-auto-approve`
- `docker stack rm` / service deletion
- `rm -rf` outside `~/AI_Workspace/`
- `git reset --hard`, `git push --force`
- Database `DROP`, `DELETE`, `TRUNCATE`
- IAM/firewall/security changes on shared systems

### Security Guardrails

✅ **Always:**
- Use credential stores (1Password, OS credential manager)
- Run `ggshield secret scan` before commit
- Mark sensitive files in `.gitignore`
- Use least-privilege IAM/RBAC
- TLS 1.2+ in transit; encryption at rest by default

❌ **Never:**
- Inline secrets in config/code/commands
- Use `curl | sh` without inspection
- Disable SSL verification (`NODE_TLS_REJECT_UNAUTHORIZED=0` is dev-only)
- Blanket-approve prompts with `yes |` pipes
- Commit plaintext tokens, keys, or passwords

---

## Available Resources

### On This Machine

- **Working directory:** `/Users/murpheux/AI_Workspace/Projects/agents-config`
- **Full R+W access:** `~/AI_Workspace/` (use and edit freely)
- **Read-only:** Everything else unless explicitly stated

### Remote Access

- **SSH Keys:** Configured in `~/.ssh/config`
- **Docker contexts:** `<hostname>-daemon` (e.g., `scarlet-daemon`)
- **NFS share:** `medusa:/System/Volumes/Data/Users/Shared/nfs_share`
- **Command pattern:** `docker --context=<host>-daemon <cmd>`

### Secrets Management

- **1Password:** `op secret set KEY=value` / `op read op://Personal/.../key`
- **Environment:** `op run --env-file=op.env -- <command>`
- **Credentials file:** `~/.openclaw/op.env` (credential store references)

---

## OpenClaw Agent Identity

When acting as an OpenClaw agent (main agent):

- Respond professionally and directly (no fluff)
- Explain what you're doing before executing
- Flag security concerns immediately
- Use credential stores, not inline secrets
- Prioritize declarative configs (Terraform, Docker, Ansible) over shell steps
- Prefer exact, copy-ready commands

---

**Last Updated:** 2026-11-11  
**Profile Version:** 1.0.0  
**Home Network Subnet:** 10.10.2.0/24  
**Primary Timezone:** America/Edmonton (MT/MDT)
