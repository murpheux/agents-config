# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

This directory is not a git repo itself — it's a working-directory umbrella over three independent projects, each with its own purpose and git status:

| Project | Git | Purpose |
|---|---|---|
| `agent-configs/` | not a git repo (yet) | **Primary project.** One source-of-truth, cost-aware multi-agent configuration, rendered into native configs for 7 AI coding tools |
| `agent-skills/` | own git repo, no remote | Murpheux's personal [Agent Skills](https://docs.warp.dev/agent-platform/warp-agents/skills) library for Warp/Oz agents |
| `ai-agents/` | fork of `ashishpatel26/500-AI-Agents-Projects` | Vendored external showcase repo of example agent implementations (not Murpheux's own code — treat as reference/read-mostly) |

Work in whichever subdirectory the task concerns; there is no shared build across them.

---

## `agent-configs/` — multi-agent configuration generator

### What it does

A single design (agent roles, guardrails, skills, slash commands) is authored once and compiled into native configuration for 7 different AI coding tools: OpenCode (the baseline), Claude Code, GitHub Copilot CLI, VS Code (Copilot Chat), Cline, Codex CLI, and Aider. Every output folder mirrors that tool's real home-directory layout (e.g. `claude-code/home/.claude/...`) and ships its own `install.sh` that backs up whatever it replaces into `~/.agent-config-backups/`.

The live OpenCode baseline (the actual source content for agents/skills) lives at `agent-configs/opencode/.config/opencode/` — `AGENTS.md`, `skills/*/SKILL.md`, agent definitions. `_shared/build.py` reads **from there**, not from `_shared/` — `_shared/` holds the generated/derived artifacts and the tool-rendering specs.

### Build, validate, test

```bash
cd agent-configs

# Regenerate every tool's config from the shared source (also normalizes CRLF -> LF)
python3 _shared/build.py                # all tools
python3 _shared/build.py claude-code     # just one tool (any _shared/tools/<tool>.yaml stem)

# Offline validation: JSON/JSONC/TOML/YAML parse, skill frontmatter spec, Codex Starlark
# rule self-checks, guard.py --self-test in every tool copy, unresolved {{PLACEHOLDERS}}
python3 _shared/validate.py

# Installer + hook smoke tests against throwaway $HOME directories
bash _shared/install_smoke.sh
```

Always run `build.py` after editing anything under `_shared/agents/`, `_shared/commands.yaml`, `_shared/guardrails/`, `_shared/tools/*.yaml`, or the OpenCode baseline — the per-tool folders (`claude-code/`, `vscode/`, `cline/`, `codex/`, `github-copilot-cli/`, `aider/`) are **generated output**; hand-editing them directly will be overwritten on the next build. Run `validate.py` before committing any generated output.

To actually install a tool's config locally:

```bash
cd agent-configs/<tool> && DRY_RUN=1 ./install.sh && ./install.sh
```

### Architecture: how a change flows through the system

1. **Source of truth** — `agent-configs/opencode/.config/opencode/AGENTS.md` and `skills/*/SKILL.md` are the canonical instructions and skills (OpenCode is the reference implementation this whole repo is modeled on). `_shared/agents/*.md` holds the 8 tool-neutral specialist prompt bodies (`router`, `explorer`, `developer`, `sre`, `planner`, `architect`, `reviewer`, `security`). `_shared/commands.yaml` defines ~16 cross-tool workflows (`/review`, `/plan`, `/commit`, `/security-scan`, etc). `_shared/guardrails/{guardrails.json,guard.py}` is the single hook implementation enforced identically everywhere (33 command rules, 18 protected paths).
2. **Per-tool rendering spec** — `_shared/tools/<tool>.yaml` tells `build.py` how to turn the generic sources into that tool's native shape: which placeholders to substitute into the AGENTS template, which agent bodies map to which output files/formats, how commands render (`claude`, `vscode`, `cline`, or `skill` format), and where the guard hook gets copied.
3. **`_shared/build.py`** does the substitution (regex-based placeholder replacement — `make_template()` fails loudly if OpenCode-specific text or an unresolved `{{PLACEHOLDER}}` leaks through) and writes the result under each tool's own top-level folder, mirroring that tool's real `$HOME` layout.
4. **`_shared/validate.py`** is a second, independent pass over the *rendered* output (not the sources) — it doesn't know about `build.py`'s internals, it just checks that whatever landed on disk is well-formed and self-consistent (parses, frontmatter correct, guard hook passes its own self-test in every copy).

### Key design invariants (don't break these when editing)

- **Router pattern**: in every tool, the main/default session is a cost-cheap `router` agent (Haiku-tier) that can only read/search and must delegate real work (edits, shell) to specialist subagents on higher tiers (Sonnet for `developer`/`sre`, Opus for `planner`/`architect`/`security`). This is enforced per-tool by a mix of permission deny-rules, the guard hook's "router gate", and (Claude Code) an OS sandbox — not by convention alone.
- **Guardrails are one file, not seven**: `_shared/guardrails/guardrails.json` + `guard.py` are copied byte-for-byte into every tool (`guard_out` in the tool yaml). Changing a rule is one edit to that pair + `build.py`, never a per-tool patch.
- **Skills are generated, not written per tool**: `_shared/skills/` (and `skills_out` destinations like `claude-code/home/.claude/skills/`) are produced from `opencode/.config/opencode/skills/*/SKILL.md` via `SKILL_SUBS` regex rewrites in `build.py` — edit the OpenCode source skill, then rebuild, don't hand-edit a rendered copy.
- **Coexistence on one machine**: `~/.copilot` is shared by the Copilot CLI and VS Code's Copilot harness (same instructions/skills/hook, agents are target-scoped); `~/.agents/skills` (Codex) is also read by Copilot CLI/Cline; VS Code's Copilot harness also reads `~/.claude/agents` and `~/.claude/skills` with `chat.useClaudeMdFile` disabled to avoid double-loading `CLAUDE.md`. Don't duplicate content across these shared locations — point to the single copy.

### Reports

`agent-configs/reports/*.pdf` — one report per tool plus `00-final-report.pdf`; source lives in `reports/_src`.

---

## `agent-skills/` — Warp/Oz skill library

Personal skill definitions for Warp/Oz agents, discovered at `.agents/skills/<skill-name>/SKILL.md`.

```bash
cd agent-skills
make validate    # scripts/validate-skills.sh — checks every SKILL.md has frontmatter name:/description:, name matches dir
make list        # scripts/list-skills.sh — prints skill names/descriptions
```

Adding a skill: create `.agents/skills/<skill-name>/SKILL.md` with YAML frontmatter (`name` must equal the directory name, plus `description`), then `make validate`.

Note: `.agents/skills/ego-browser/` is a point-in-time snapshot of an externally-maintained skill (`~/.local/share/ego/ego-skills`, consumed elsewhere as a symlink) — re-sync it manually when upstream changes; don't treat it as this repo's own source.

---

## `ai-agents/` — vendored external repo

This is a fork of `ashishpatel26/500-AI-Agents-Projects`, a curated collection of example agent implementations across frameworks (LangGraph, CrewAI, AutoGen, Agno, LlamaIndex) and industries. Each example under `agents/NN-*-agent/` is self-contained with its own `requirements.txt` and `.env.example`:

```bash
cd ai-agents/agents/<NN-example-agent>
pip install -r requirements.txt
cp .env.example .env   # add the required API key
python agent.py
```

There's also `crewai_mcp_course/` (a multi-lesson CrewAI + MCP tutorial). Treat this project as reference material / upstream fork rather than Murpheux's own architecture — changes here should generally go upstream via the documented PR process in `CONTRIBUTION.md`, not diverge locally, unless the task explicitly calls for a local example.
