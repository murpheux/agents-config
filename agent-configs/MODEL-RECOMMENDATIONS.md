# Model recommendations per agent — cost · speed · capability

_Prepared for Murpheux · 28 Sep 2026 · applies to the router/specialist team in every config under `~/agent-configs`._

**Prices** are $ per 1M tokens (input / cached / output), from GitHub's Copilot price table (`github/docs` → `data/tables/copilot/models-and-pricing.yml`, the providers' list prices). DeepSeek V4 Flash is from third-party price trackers. **Effective cost** = cost of one typical call under the token profile shown for each agent (reasoning tokens are billed as output), plus the cost per 100 calls. **Speed** and **capability** are relative ratings (●●●●● = best) based on model class and tier. They are guidance, not benchmarks.

## Quick answer (#1 pick per agent)

| Agent | #1 pick | Effort | Effective cost / call | Currently configured |
|---|---|---|---|---|
| **router** | GPT-6 Luna | medium | $0.0009 | DeepSeek V4 Flash |
| **explorer** | GPT-6 Luna | low | $0.0036 | DeepSeek V4 Flash |
| **reviewer** | GPT-6 Luna | high | $0.0035 | DeepSeek V4 Flash |
| **planner** | GPT-6 Sol | medium | $0.118 | GPT-6 Sol ✔ |
| **developer** | Claude Sonnet 5 | medium | $0.412 | Claude Sonnet 5 ✔ |
| **sre** | Claude Sonnet 5 | medium | $0.258 | Claude Sonnet 5 ✔ |
| **architect** | GPT-6 Sol | high/xhigh | $0.286 | GPT-6 Sol ✔ |
| **security** | Claude Opus 5.5 | high | $0.508 | Claude Opus 5.5 ✔ |

## Per-agent top 5 (in order of preference)

### router — Triage every request, answer SIMPLE ones, delegate

Token profile per call: **15,000 input** (85% cached) · **700 output** + **300 reasoning** · frequency: every turn.

| # | Model | Effort | $/1M in / cached / out | Effective cost / call | per 100 calls | Speed | Capability | Why | Available via |
|---|---|---|---|---|---|---|---|---|---|
| 1 | **GPT-6 Luna** | medium | $0.1 / $0.01 / $0.5 | $0.0009 | $0.085 | ●●●●● | ●●●○○ | Near-lowest cost (DeepSeek is ~30% cheaper per call here), faster, and a stronger instruction-follower. Ideal for high-frequency triage | Copilot · Codex · gateway |
| 2 | **DeepSeek V4 Flash** _(current)_ | — | $0.14 / $0.0028 / $0.28 | $0.0006 | $0.063 | ●●●●○ | ●●●○○ | Current router. Cheapest per call because of its 98% cache discount on the stable system prompt; a little slower | gateway (`deepseek-flash`) |
| 3 | **Gemini 3.8 Flash** | low | $0.75 / $0.075 / $3.75 | $0.0064 | $0.639 | ●●●●● | ●●●○○ | Fastest option with more reasoning headroom for ambiguous requests | Copilot · gateway |
| 4 | **Claude Haiku 5.5** | — | $1 / $0.1 / $5 | $0.0085 | $0.852 | ●●●●● | ●●●○○ | Most reliable tool-calling and delegation; ~10× the cost of Luna | Claude Code · Copilot · gateway |
| 5 | **GPT-5 mini** | low | $0.25 / $0.025 / $2 | $0.0029 | $0.288 | ●●●●○ | ●●○○○ | Fallback on Copilot plans where the newer lightweight models are unavailable | Copilot CLI |

### explorer — Read-only codebase/doc search

Token profile per call: **40,000 input** (40% cached) · **1,500 output** + **500 reasoning** · frequency: several per task.

| # | Model | Effort | $/1M in / cached / out | Effective cost / call | per 100 calls | Speed | Capability | Why | Available via |
|---|---|---|---|---|---|---|---|---|---|
| 1 | **GPT-6 Luna** | low | $0.1 / $0.01 / $0.5 | $0.0036 | $0.356 | ●●●●● | ●●●○○ | Input-heavy work at the lowest price | Copilot · Codex · gateway |
| 2 | **DeepSeek V4 Flash** _(current)_ | — | $0.14 / $0.0028 / $0.28 | $0.0040 | $0.396 | ●●●●○ | ●●●○○ | Equally cheap; 1M-token context for large repos | gateway (`deepseek-flash`) |
| 3 | **Gemini 3.8 Flash** | low | $0.75 / $0.075 / $3.75 | $0.027 | $2.67 | ●●●●● | ●●●○○ | Fastest large-context reads when accuracy matters more | Copilot · gateway |
| 4 | **GPT-5.6 Luna** | low | $0.2 / $0.02 / $1.2 | $0.0075 | $0.752 | ●●●●● | ●●●○○ | Stable previous-gen fallback | Copilot · Codex · gateway |
| 5 | **Qwen3-Coder 30B (local)** | — | free (local) | $0 (hardware) | $0 (hardware) | ●●○○○ | ●●○○○ | No token cost for private repos; slower, so for background exploration only | Ollama on medusa |

### reviewer — Independent diff review

Token profile per call: **25,000 input** (30% cached) · **1,800 output** + **1,500 reasoning** · frequency: per meaningful diff.

| # | Model | Effort | $/1M in / cached / out | Effective cost / call | per 100 calls | Speed | Capability | Why | Available via |
|---|---|---|---|---|---|---|---|---|---|
| 1 | **GPT-6 Luna** | high | $0.1 / $0.01 / $0.5 | $0.0035 | $0.347 | ●●●●● | ●●●○○ | Cheap, and a different model family from the Sonnet developer, which makes the review more independent | Copilot · Codex · gateway |
| 2 | **Gemini 3.8 Flash** | medium | $0.75 / $0.075 / $3.75 | $0.026 | $2.61 | ●●●●● | ●●●○○ | Also a different family; better at subtle logic, still cheap | Copilot · gateway |
| 3 | **DeepSeek V4 Flash** _(current)_ | — | $0.14 / $0.0028 / $0.28 | $0.0034 | $0.340 | ●●●●○ | ●●●○○ | Current reviewer; cheapest; fine for routine diffs | gateway (`deepseek-flash`) |
| 4 | **Claude Haiku 5.5** | — | $1 / $0.1 / $5 | $0.035 | $3.48 | ●●●●● | ●●●○○ | Precise and fast; same family as the developer | Claude Code · Copilot · gateway |
| 5 | **Kimi K2.7 Code** | — | $0.95 / $0.19 / $4 | $0.031 | $3.12 | ●●●○○ | ●●●●○ | Code specialist; good at bug-spotting; flat-rate via Ollama cloud | Copilot · gateway (Ollama cloud) |

### planner — Short executable plans

Token profile per call: **35,000 input** (50% cached) · **3,000 output** + **5,000 reasoning** · frequency: COMPLEX work only.

| # | Model | Effort | $/1M in / cached / out | Effective cost / call | per 100 calls | Speed | Capability | Why | Available via |
|---|---|---|---|---|---|---|---|---|---|
| 1 | **GPT-6 Sol** _(current)_ | medium | $2 / $0.2 / $10 | $0.118 | $11.85 | ●●●○○ | ●●●●● | Best reasoning per dollar (current planner) | Copilot · Codex · OpenRouter |
| 2 | **Claude Sonnet 5** | medium | $2 / $0.2 / $10 | $0.118 | $11.85 | ●●●○○ | ●●●●● | Same price; strongest at repo-grounded plans | Claude Code · Copilot · gateway |
| 3 | **GPT-5.6 Terra** | medium | $2 / $0.2 / $12 | $0.135 | $13.45 | ●●●○○ | ●●●●○ | Solid versatile alternative at the same input price | Copilot · Codex · gateway |
| 4 | **Grok 4.7** | — | $2 / $0.5 / $6 | $0.092 | $9.18 | ●●●●○ | ●●●○○ | Cheapest output in this tier; verify plan quality on your repos | Copilot |
| 5 | **Claude Opus 5.5** | medium | $4 / $0.2 / $20 | $0.234 | $23.35 | ●●○○○ | ●●●●● | For HIGH_RISK plans where a wrong decomposition is costly | Claude Code · Copilot · OpenRouter |

### developer — Implementation + validation (agentic, multi-step)

Token profile per call: **250,000 input** (75% cached) · **15,000 output** + **10,000 reasoning** · frequency: per task.

| # | Model | Effort | $/1M in / cached / out | Effective cost / call | per 100 calls | Speed | Capability | Why | Available via |
|---|---|---|---|---|---|---|---|---|---|
| 1 | **Claude Sonnet 5** _(current)_ | medium | $2 / $0.2 / $10 | $0.412 | $41.25 | ●●●○○ | ●●●●● | Best agentic coding value (current developer) | Claude Code · Copilot · gateway |
| 2 | **GPT-6 Sol** | medium | $2 / $0.2 / $10 | $0.412 | $41.25 | ●●●○○ | ●●●●● | Same price; excellent at Go/C#/Python; strong at tests | Copilot · Codex · OpenRouter |
| 3 | **Kimi K2.7 Code** | — | $0.95 / $0.19 / $4 | $0.195 | $19.50 | ●●●○○ | ●●●●○ | About 2× cheaper and coding-tuned; flat-rate via Ollama cloud; for NORMAL tasks | Copilot · gateway (Ollama cloud) |
| 4 | **GPT-5.3-Codex** | medium | $1.75 / $0.175 / $14 | $0.492 | $49.22 | ●●●○○ | ●●●●○ | Coding-tuned, but expensive output; good for large refactors | Copilot · Codex · gateway |
| 5 | **Claude Opus 5.5** | medium | $4 / $0.2 / $20 | $0.787 | $78.75 | ●●○○○ | ●●●●● | Escalation for the hardest implementations; 2× Sonnet | Claude Code · Copilot · OpenRouter |

### sre — Live-system diagnosis (log/command-output heavy)

Token profile per call: **150,000 input** (60% cached) · **6,000 output** + **6,000 reasoning** · frequency: per incident.

| # | Model | Effort | $/1M in / cached / out | Effective cost / call | per 100 calls | Speed | Capability | Why | Available via |
|---|---|---|---|---|---|---|---|---|---|
| 1 | **Claude Sonnet 5** _(current)_ | medium | $2 / $0.2 / $10 | $0.258 | $25.80 | ●●●○○ | ●●●●● | Most reliable multi-step tool use under uncertainty (current) | Claude Code · Copilot · gateway |
| 2 | **GPT-6 Sol** | medium | $2 / $0.2 / $10 | $0.258 | $25.80 | ●●●○○ | ●●●●● | Same price; strong root-cause reasoning | Copilot · Codex · OpenRouter |
| 3 | **Gemini 3.8 Flash** | medium | $0.75 / $0.075 / $3.75 | $0.097 | $9.68 | ●●●●● | ●●●○○ | Cheap first-pass triage of large logs; escalate if unclear | Copilot · gateway |
| 4 | **Kimi K2.7 Code** | — | $0.95 / $0.19 / $4 | $0.122 | $12.21 | ●●●○○ | ●●●●○ | Budget option for scripted, routine checks | Copilot · gateway (Ollama cloud) |
| 5 | **Claude Opus 5.5** | high | $4 / $0.2 / $20 | $0.498 | $49.80 | ●●○○○ | ●●●●● | Major incidents where time-to-root-cause matters more than cost | Claude Code · Copilot · OpenRouter |

### architect — Design, trade-offs, ADRs, hard root cause

Token profile per call: **60,000 input** (50% cached) · **7,000 output** + **15,000 reasoning** · frequency: EXPERT work only.

| # | Model | Effort | $/1M in / cached / out | Effective cost / call | per 100 calls | Speed | Capability | Why | Available via |
|---|---|---|---|---|---|---|---|---|---|
| 1 | **GPT-6 Sol** _(current)_ | high/xhigh | $2 / $0.2 / $10 | $0.286 | $28.60 | ●●●○○ | ●●●●● | Deep reasoning at workhorse prices (current architect) | Copilot · Codex · OpenRouter |
| 2 | **Claude Opus 5.5** | high | $4 / $0.2 / $20 | $0.566 | $56.60 | ●●○○○ | ●●●●● | Premium design quality and writing; ~2× Sol | Claude Code · Copilot · OpenRouter |
| 3 | **Claude Sonnet 5** | high | $2 / $0.2 / $10 | $0.286 | $28.60 | ●●●○○ | ●●●●● | Budget architecture for well-understood domains | Claude Code · Copilot · gateway |
| 4 | **GPT-6 Astra** | medium | $10 / $1 / $50 | $1.43 | $143.00 | ●○○○○ | ●●●●● | Hardest distributed-systems and scale problems; ~5× Sol | Copilot · Codex · gateway |
| 5 | **Claude Fable 5.1** | high | $10 / $0.25 / $50 | $1.41 | $140.75 | ●●○○○ | ●●●●● | Rare, highest-stakes designs; the most expensive model | Claude Code · Copilot |

### security — Threat models, IAM/vuln review, HIGH_RISK review

Token profile per call: **80,000 input** (50% cached) · **5,000 output** + **12,000 reasoning** · frequency: HIGH_RISK / security only.

| # | Model | Effort | $/1M in / cached / out | Effective cost / call | per 100 calls | Speed | Capability | Why | Available via |
|---|---|---|---|---|---|---|---|---|---|
| 1 | **Claude Opus 5.5** _(current)_ | high | $4 / $0.2 / $20 | $0.508 | $50.80 | ●●○○○ | ●●●●● | Most rigorous careful reviewer (current security agent) | Claude Code · Copilot · OpenRouter |
| 2 | **GPT-6 Sol** | high | $2 / $0.2 / $10 | $0.258 | $25.80 | ●●●○○ | ●●●●● | A different family from the Sonnet developer; ~½ the cost of Opus 5.5 | Copilot · Codex · OpenRouter |
| 3 | **GPT-6 Astra** | medium | $10 / $1 / $50 | $1.29 | $129.00 | ●○○○○ | ●●●●● | Maximum rigor for production IAM/data changes | Copilot · Codex · gateway |
| 4 | **Claude Fable 5.1** | high | $10 / $0.25 / $50 | $1.26 | $126.00 | ●●○○○ | ●●●●● | Top-tier second opinion for critical changes only | Claude Code · Copilot |
| 5 | **Claude Sonnet 5** | high | $2 / $0.2 / $10 | $0.258 | $25.80 | ●●●○○ | ●●●●● | Budget security pass for low-exposure changes | Claude Code · Copilot · gateway |

## How the ranking was made

- **Preference order** balances capability for the role first (a router that mis-routes, or a reviewer that misses bugs, costs more than it saves), then effective cost, then speed.
- **Cheap roles** (router, explorer, reviewer) run on nearly every turn, so they favour the lowest effective cost with adequate tool-use reliability.
- **Workhorse roles** (developer, sre, planner) favour agentic reliability at the $2/$10 tier.
- **Premium roles** (architect, security) favour depth of reasoning; they run only for EXPERT or HIGH_RISK work.
- **Independence**: reviewer and security picks favour a different model family from the developer (Sonnet 5), which makes the review more independent.
- **Caching** dominates long agentic sessions. The developer profile assumes 75% of input is cached; in that case output and reasoning tokens drive the bill.
- **Flat-rate options** (Ollama cloud models via the gateway, local Ollama) have no per-token cost within plan limits. The table shows their list price or $0, so compare them with your subscription.

## Recommended changes to the current configs

- **router / explorer**: consider **GPT-6 Luna** where available (Copilot, Codex, VS Code). It costs about the same as DeepSeek V4 Flash (the router pays slightly more because Flash's cached input is ~4× cheaper) and is typically faster; keep DeepSeek V4 Flash on the gateway (OpenCode, Aider, Cline).
- **reviewer**: move from DeepSeek V4 Flash to **GPT-6 Luna (high)** or **Gemini 3.8 Flash** where available, for better bug-finding at still-trivial cost.
- **developer**: keep **Claude Sonnet 5**. Use **Kimi K2.7 Code** (flat-rate via Ollama cloud) for NORMAL tasks to roughly halve spend.
- **security**: keep **Claude Opus 5.5** for HIGH_RISK work; **GPT-6 Sol (high)** is a strong, cheaper, different-family reviewer for routine security passes.
- **architect**: keep **GPT-6 Sol**; escalate to **Opus 5.5** or **Astra** only for the hardest designs.
