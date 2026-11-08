#!/usr/bin/env python3
"""Generate MODEL-RECOMMENDATIONS.md (+ HTML for the PDF) — top-5 models per agent with effective cost.

Prices: $ per 1M tokens (input / cached input / output). Source: github/docs data/tables/copilot/models-and-pricing.yml
(Copilot pass-through list prices, Sep 2026) unless noted. Reasoning tokens are billed as output.
Effective cost per call = uncached_in*in + cached_in*cached + (output + reasoning)*out.
"""
from __future__ import annotations

import html
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent

# model: (input, cached, output, speed 1-5, capability 1-5, where available, note)
M = {
    "GPT-6 Luna":         (0.10, 0.01, 0.50, 5, 3, "Copilot · Codex · gateway", "lightweight, newest gen"),
    "DeepSeek V4 Flash":  (0.14, 0.0028, 0.28, 4, 3, "gateway (`deepseek-flash`)", "price from third-party trackers; 98% cache discount"),
    "Gemini 3.8 Flash":   (0.75, 0.075, 3.75, 5, 3, "Copilot · gateway", "promo price; large context"),
    "GPT-5.6 Luna":       (0.20, 0.02, 1.20, 5, 3, "Copilot · Codex · gateway", "lightweight, previous gen"),
    "GPT-5 mini":         (0.25, 0.025, 2.00, 4, 2, "Copilot CLI", "older lightweight"),
    "Claude Haiku 4.5":   (1.00, 0.10, 5.00, 5, 3, "Claude Code · Copilot · gateway", "very reliable tool use"),
    "MAI-Code-1.1-Flash": (0.20, 0.02, 1.20, 5, 2, "Copilot", "Microsoft lightweight coder"),
    "Qwen3-Coder 30B (local)": (0.0, 0.0, 0.0, 2, 2, "Ollama on medusa", "no token cost; slower, weaker tool use"),
    "Kimi K2.7 Code":     (0.95, 0.19, 4.00, 3, 4, "Copilot · gateway (Ollama cloud)", "open-weight coding model; flat-rate via Ollama cloud"),
    "Grok 4.7":           (2.00, 0.50, 6.00, 4, 3, "Copilot", "cheap output"),
    "GPT-5.6 Terra":      (2.00, 0.20, 12.00, 3, 4, "Copilot · Codex · gateway", "versatile"),
    "GPT-6 Sol":          (2.00, 0.20, 10.00, 3, 5, "Copilot · Codex · OpenRouter", "best-value reasoning"),
    "Claude Sonnet 5":    (2.00, 0.20, 10.00, 3, 5, "Claude Code · Copilot · gateway", "best-value agentic coding"),
    "GPT-5.3-Codex":      (1.75, 0.175, 14.00, 3, 4, "Copilot · Codex · gateway", "coding-tuned, expensive output"),
    "Claude Opus 5.5":    (4.00, 0.20, 20.00, 2, 5, "Claude Code · Copilot · OpenRouter", "premium; cheaper than Opus 5/4.8"),
    "GPT-6 Astra":        (10.00, 1.00, 50.00, 1, 5, "Copilot · Codex · gateway", "top reasoning, most expensive OpenAI"),
    "Claude Fable 5.1":   (10.00, 0.25, 50.00, 2, 5, "Claude Code · Copilot", "top Anthropic; use rarely"),
}

# agent: (description, input tokens, cached share, visible output, reasoning, calls note, [ (model, effort, why) x5 ])
A = {
    "router": ("Triage every request, answer SIMPLE ones, delegate", 15_000, 0.85, 700, 300, "every turn",
        [("GPT-6 Luna", "medium", "Near-lowest cost (DeepSeek is ~30% cheaper per call here), faster, and a stronger instruction-follower. Ideal for high-frequency triage"),
         ("DeepSeek V4 Flash", "—", "Current router. Cheapest per call because of its 98% cache discount on the stable system prompt; a little slower"),
         ("Gemini 3.8 Flash", "low", "Fastest option with more reasoning headroom for ambiguous requests"),
         ("Claude Haiku 4.5", "—", "Most reliable tool-calling and delegation; ~10× the cost of Luna"),
         ("GPT-5 mini", "low", "Fallback on Copilot plans where the newer lightweight models are unavailable")]),
    "explorer": ("Read-only codebase/doc search", 40_000, 0.40, 1_500, 500, "several per task",
        [("GPT-6 Luna", "low", "Input-heavy work at the lowest price"),
         ("DeepSeek V4 Flash", "—", "Equally cheap; 1M-token context for large repos"),
         ("Gemini 3.8 Flash", "low", "Fastest large-context reads when accuracy matters more"),
         ("GPT-5.6 Luna", "low", "Stable previous-gen fallback"),
         ("Qwen3-Coder 30B (local)", "—", "No token cost for private repos; slower, so for background exploration only")]),
    "reviewer": ("Independent diff review", 25_000, 0.30, 1_800, 1_500, "per meaningful diff",
        [("GPT-6 Luna", "high", "Cheap, and a different model family from the Sonnet developer, which makes the review more independent"),
         ("Gemini 3.8 Flash", "medium", "Also a different family; better at subtle logic, still cheap"),
         ("DeepSeek V4 Flash", "—", "Current reviewer; cheapest; fine for routine diffs"),
         ("Claude Haiku 4.5", "—", "Precise and fast; same family as the developer"),
         ("Kimi K2.7 Code", "—", "Code specialist; good at bug-spotting; flat-rate via Ollama cloud")]),
    "planner": ("Short executable plans", 35_000, 0.50, 3_000, 5_000, "COMPLEX work only",
        [("GPT-6 Sol", "medium", "Best reasoning per dollar (current planner)"),
         ("Claude Sonnet 5", "medium", "Same price; strongest at repo-grounded plans"),
         ("GPT-5.6 Terra", "medium", "Solid versatile alternative at the same input price"),
         ("Grok 4.7", "—", "Cheapest output in this tier; verify plan quality on your repos"),
         ("Claude Opus 5.5", "medium", "For HIGH_RISK plans where a wrong decomposition is costly")]),
    "developer": ("Implementation + validation (agentic, multi-step)", 250_000, 0.75, 15_000, 10_000, "per task",
        [("Claude Sonnet 5", "medium", "Best agentic coding value (current developer)"),
         ("GPT-6 Sol", "medium", "Same price; excellent at Go/C#/Python; strong at tests"),
         ("Kimi K2.7 Code", "—", "About 2× cheaper and coding-tuned; flat-rate via Ollama cloud; for NORMAL tasks"),
         ("GPT-5.3-Codex", "medium", "Coding-tuned, but expensive output; good for large refactors"),
         ("Claude Opus 5.5", "medium", "Escalation for the hardest implementations; 2× Sonnet")]),
    "sre": ("Live-system diagnosis (log/command-output heavy)", 150_000, 0.60, 6_000, 6_000, "per incident",
        [("Claude Sonnet 5", "medium", "Most reliable multi-step tool use under uncertainty (current)"),
         ("GPT-6 Sol", "medium", "Same price; strong root-cause reasoning"),
         ("Gemini 3.8 Flash", "medium", "Cheap first-pass triage of large logs; escalate if unclear"),
         ("Kimi K2.7 Code", "—", "Budget option for scripted, routine checks"),
         ("Claude Opus 5.5", "high", "Major incidents where time-to-root-cause matters more than cost")]),
    "architect": ("Design, trade-offs, ADRs, hard root cause", 60_000, 0.50, 7_000, 15_000, "EXPERT work only",
        [("GPT-6 Sol", "high/xhigh", "Deep reasoning at workhorse prices (current architect)"),
         ("Claude Opus 5.5", "high", "Premium design quality and writing; ~2× Sol"),
         ("Claude Sonnet 5", "high", "Budget architecture for well-understood domains"),
         ("GPT-6 Astra", "medium", "Hardest distributed-systems and scale problems; ~5× Sol"),
         ("Claude Fable 5.1", "high", "Rare, highest-stakes designs; the most expensive model")]),
    "security": ("Threat models, IAM/vuln review, HIGH_RISK review", 80_000, 0.50, 5_000, 12_000, "HIGH_RISK / security only",
        [("Claude Opus 5.5", "high", "Most rigorous careful reviewer (current security agent)"),
         ("GPT-6 Sol", "high", "A different family from the Sonnet developer; ~½ the cost of Opus 5.5"),
         ("GPT-6 Astra", "medium", "Maximum rigor for production IAM/data changes"),
         ("Claude Fable 5.1", "high", "Top-tier second opinion for critical changes only"),
         ("Claude Sonnet 5", "high", "Budget security pass for low-exposure changes")]),
}

CURRENT = {"router": "DeepSeek V4 Flash", "explorer": "DeepSeek V4 Flash", "reviewer": "DeepSeek V4 Flash",
           "planner": "GPT-6 Sol", "developer": "Claude Sonnet 5", "sre": "Claude Sonnet 5",
           "architect": "GPT-6 Sol", "security": "Claude Opus 5.5"}


def cost(model: str, tin: int, cached: float, out: int, reasoning: int) -> float:
    pi, pc, po = M[model][:3]
    return (tin * (1 - cached) * pi + tin * cached * pc + (out + reasoning) * po) / 1e6


def money(x: float) -> str:
    if x == 0:
        return "$0 (hardware)"
    return f"${x:.4f}" if x < 0.01 else f"${x:.3f}" if x < 1 else f"${x:.2f}"


def stars(n: int) -> str:
    return "●" * n + "○" * (5 - n)


def build() -> tuple[str, str]:
    md = ["# Model recommendations per agent — cost · speed · capability",
          "",
          "_Prepared for Murpheux · 28 Sep 2026 · applies to the router/specialist team in every config under `~/agent-configs`._",
          "",
          "**Prices** are $ per 1M tokens (input / cached / output), from GitHub's Copilot price table (`github/docs` → "
          "`data/tables/copilot/models-and-pricing.yml`, the providers' list prices). DeepSeek V4 Flash is from third-party "
          "price trackers. **Effective cost** = cost of one typical call under the token profile shown for each agent "
          "(reasoning tokens are billed as output), plus the cost per 100 calls. **Speed** and **capability** are relative "
          "ratings (●●●●● = best) based on model class and tier. They are guidance, not benchmarks.",
          "",
          "## Quick answer (#1 pick per agent)",
          "",
          "| Agent | #1 pick | Effort | Effective cost / call | Currently configured |",
          "|---|---|---|---|---|"]
    for a, (desc, tin, cached, out, reas, freq, picks) in A.items():
        m, eff, _ = picks[0]
        cur = CURRENT[a]
        md.append(f"| **{a}** | {m} | {eff} | {money(cost(m, tin, cached, out, reas))} | {cur}{' ✔' if cur == m else ''} |")
    md += ["", "## Per-agent top 5 (in order of preference)", ""]
    for a, (desc, tin, cached, out, reas, freq, picks) in A.items():
        md += [f"### {a} — {desc}",
               "",
               f"Token profile per call: **{tin:,} input** ({int(cached * 100)}% cached) · **{out:,} output** + **{reas:,} reasoning** · frequency: {freq}.",
               "",
               "| # | Model | Effort | $/1M in / cached / out | Effective cost / call | per 100 calls | Speed | Capability | Why | Available via |",
               "|---|---|---|---|---|---|---|---|---|---|"]
        for i, (m, eff, why) in enumerate(picks, 1):
            pi, pc, po, sp, cap, where, note = M[m]
            c = cost(m, tin, cached, out, reas)
            price = "free (local)" if pi == 0 else f"${pi:g} / ${pc:g} / ${po:g}"
            cur = " _(current)_" if CURRENT[a] == m else ""
            md.append(f"| {i} | **{m}**{cur} | {eff} | {price} | {money(c)} | {money(c * 100)} | {stars(sp)} | {stars(cap)} | {why} | {where} |")
        md.append("")
    md += ["## How the ranking was made",
           "",
           "- **Preference order** balances capability for the role first (a router that mis-routes, or a reviewer that misses bugs, costs more than it saves), then effective cost, then speed.",
           "- **Cheap roles** (router, explorer, reviewer) run on nearly every turn, so they favour the lowest effective cost with adequate tool-use reliability.",
           "- **Workhorse roles** (developer, sre, planner) favour agentic reliability at the $2/$10 tier.",
           "- **Premium roles** (architect, security) favour depth of reasoning; they run only for EXPERT or HIGH_RISK work.",
           "- **Independence**: reviewer and security picks favour a different model family from the developer (Sonnet 5), which makes the review more independent.",
           "- **Caching** dominates long agentic sessions. The developer profile assumes 75% of input is cached; in that case output and reasoning tokens drive the bill.",
           "- **Flat-rate options** (Ollama cloud models via the gateway, local Ollama) have no per-token cost within plan limits. The table shows their list price or $0, so compare them with your subscription.",
           "",
           "## Recommended changes to the current configs",
           "",
           "- **router / explorer**: consider **GPT-6 Luna** where available (Copilot, Codex, VS Code). It costs about the same as DeepSeek V4 Flash (the router pays slightly more because Flash's cached input is ~4× cheaper) and is typically faster; keep DeepSeek V4 Flash on the gateway (OpenCode, Aider, Cline).",
           "- **reviewer**: move from DeepSeek V4 Flash to **GPT-6 Luna (high)** or **Gemini 3.8 Flash** where available, for better bug-finding at still-trivial cost.",
           "- **developer**: keep **Claude Sonnet 5**. Use **Kimi K2.7 Code** (flat-rate via Ollama cloud) for NORMAL tasks to roughly halve spend.",
           "- **security**: keep **Claude Opus 5.5** for HIGH_RISK work; **GPT-6 Sol (high)** is a strong, cheaper, different-family reviewer for routine security passes.",
           "- **architect**: keep **GPT-6 Sol**; escalate to **Opus 5.5** or **Astra** only for the hardest designs.",
           ""]
    text = "\n".join(md)
    return text, to_html(text)


def to_html(md: str) -> str:
    """Tiny Markdown→HTML for this document (headings, paragraphs, lists, tables, bold/italic/code)."""
    def inline(s: str) -> str:
        s = html.escape(s, quote=False)
        s = re.sub(r"`([^`]+)`", r"<code>\1</code>", s)
        s = re.sub(r"\*\*([^*]+)\*\*", r"<b>\1</b>", s)
        s = re.sub(r"(?<![\w*])_([^_]+)_(?!\w)", r"<i>\1</i>", s)
        return s
    out, lines, i = [], md.splitlines(), 0
    while i < len(lines):
        ln = lines[i]
        if ln.startswith("|"):
            rows = []
            while i < len(lines) and lines[i].startswith("|"):
                if not re.match(r"^\|[-| ]+\|$", lines[i]):
                    rows.append([c.strip() for c in lines[i].strip("|").split("|")])
                i += 1
            out.append("<table><tr>" + "".join(f"<th>{inline(c)}</th>" for c in rows[0]) + "</tr>")
            out += ["<tr>" + "".join(f"<td>{inline(c)}</td>" for c in r) + "</tr>" for r in rows[1:]]
            out.append("</table>")
            continue
        if ln.startswith("### "):
            out.append(f"<h3>{inline(ln[4:])}</h3>")
        elif ln.startswith("## "):
            out.append(f"<h2>{inline(ln[3:])}</h2>")
        elif ln.startswith("# "):
            out.append(f"<div class='cover'><h1>{inline(ln[2:])}</h1>")
            if i + 2 < len(lines) and lines[i + 2].startswith("_"):
                out.append(f"<div class='sub'>{inline(lines[i + 2])}</div></div>")
                i += 2
            else:
                out.append("</div>")
        elif ln.startswith("- "):
            out.append("<ul>")
            while i < len(lines) and lines[i].startswith("- "):
                out.append(f"<li>{inline(lines[i][2:])}</li>")
                i += 1
            out.append("</ul>")
            continue
        elif ln.strip():
            out.append(f"<p>{inline(ln)}</p>")
        i += 1
    body = "\n".join(out)
    return (f"<!DOCTYPE html><html lang='en'><head><meta charset='utf-8'><title>Model recommendations</title>"
            f"<link rel='stylesheet' href='style.css'><style>@page {{ size: A4 landscape; margin: 12mm; }} "
            f"td:nth-child(7), td:nth-child(8) {{ white-space: nowrap; letter-spacing: -1px; }}</style></head><body>{body}</body></html>")


if __name__ == "__main__":
    md, page = build()
    (ROOT / "MODEL-RECOMMENDATIONS.md").write_text(md, encoding="utf-8")
    (ROOT / "reports/_src/model-recommendations.html").write_text(page, encoding="utf-8")
    print(md)
