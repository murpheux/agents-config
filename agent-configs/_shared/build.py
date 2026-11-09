#!/usr/bin/env python3
"""Build per-tool agent configurations from one source of truth.

Sources
  ~/opencode/.config/opencode/AGENTS.md   → _shared/AGENTS.template.md (tool placeholders)
  ~/opencode/.config/opencode/skills/*    → _shared/skills/* (Agent Skills spec: name == folder id)
  _shared/agents/*.md                     → specialist prompt bodies
  _shared/guardrails/{guard.py,guardrails.json}
  _shared/tools/<tool>.yaml               → per-tool rendering spec

Run:  python3 _shared/build.py [tool ...]      (no args = all tools with a spec)
"""
from __future__ import annotations

import json
import re
import shutil
import sys
from pathlib import Path

import yaml

ROOT = Path(__file__).resolve().parent.parent
SHARED = ROOT / "_shared"
OPENCODE = ROOT / "opencode/.config/opencode"  # OpenCode baseline (moved into agent-configs)

# ── 1. instruction template ──────────────────────────────────────────────────────────────────────
TEMPLATE_SUBS: list[tuple[str, str]] = [
    (r"> \*\*OpenCode v2 note:\*\*.*?\n", "{{TOOL_NOTE}}\n"),
    (r"\(LLM gateway used by OpenCode\)", "(LLM gateway used by AI coding agents)"),
    (r"\(the worst are hard-blocked by policy — prepare the command and let me run it\)",
     "(the worst are hard-blocked by the tool's guardrails — prepare the command and let me run it)"),
    (r"\*\(Merged from the former `policies/security-guardrails\.md`; enforced by `experimental\.policies` \+ `permissions` in `opencode\.jsonc`\.\)\*",
     "*(Enforced by: {{TOOL_ENFORCEMENT_SUMMARY}})*"),
    (r"1Password data or OpenCode's `service\.json`",
     "1Password data or AI-tool credential/state files (OpenCode `service.json`, `~/.claude/.credentials.json`, `~/.codex/auth.json`, Copilot/Cline token stores)"),
    (r"- OpenCode permissions and hard-deny policies are authoritative\. ", "- {{TOOL_ENFORCEMENT_TEXT}} "),
    (r"## 14\. OpenCode Agent Team & Cost Discipline\n\n.*?\nCost rules for every agent:",
     "## 14. Agent Team & Cost Discipline\n\n{{TOOL_TEAM}}\n\nCost rules for every agent:"),
    (r"Interactive programs are denied by permission\.", "{{TOOL_INTERACTIVE}}"),
    (r"How OpenCode enforces this: .*?\n", "{{TOOL_APPROVALS}}\n"),
    (r"- Load skills \(`skills/`\) only when", "- Load skills only when"),
]

SKILL_SUBS: list[tuple[str, str]] = [
    (r" — pre-approved\.", " — read-only (safe to auto-approve)."),
    (r" \(both pre-approved\)", " (read-only, safe to auto-approve)"),
    (r" \(pre-approved\)", " (read-only, safe to auto-approve)"),
    (r" — asks approval \(touches cloud APIs\)\.", " — requires approval (touches cloud APIs)."),
    (r" — asks approval\.", " — requires approval."),
    (r"apply/upgrade asks approval; `kubectl delete namespace` is hard-denied\.",
     "apply/upgrade requires approval; `kubectl delete namespace` is blocked by the guardrails."),
    (r"# asks approval", "# requires approval"),
    (r"\(hard-denied\)", "(blocked by the guardrails)"),
    (r"`destroy` and `-auto-approve` are hard-denied\.", "`destroy` and `-auto-approve` are blocked by the guardrails."),
    (r"agents are denied by policy\.", "agent guardrails block reading it."),
    (r"or the `github` MCP actions tools", "or the GitHub MCP server's Actions tools"),
    (r"Use the `awsdocs` MCP", "Use the AWS Documentation MCP server (when configured)"),
    (r"Use the `mslearn` MCP", "Use the Microsoft Learn MCP server (when configured)"),
    (r"Use the `terraform` MCP \(HashiCorp registry\)", "Use the Terraform registry MCP server (when configured)"),
    (r'<mxfile host="opencode"', '<mxfile host="ai-agent"'),
    (r"The `read` tool can show", "File-read tools can show"),
]


def make_template() -> str:
    text = (OPENCODE / "AGENTS.md").read_text(encoding="utf-8")
    for pattern, repl in TEMPLATE_SUBS:
        new, n = re.subn(pattern, repl.replace("\\", "\\\\"), text, flags=re.S)
        if n == 0:
            raise SystemExit(f"template substitution did not match: {pattern[:60]}")
        text = new
    leftovers = [m.group(0) for m in re.finditer(r"(?i)opencode[^\n]{0,40}", text)]
    allowed = ("OpenCode, and any AI", "OpenCode `service.json`")
    leftovers = [x for x in leftovers if not any(a in x for a in allowed)]
    if leftovers:
        raise SystemExit(f"OpenCode-specific text left in template: {leftovers}")
    (SHARED / "AGENTS.template.md").write_text(text, encoding="utf-8")
    return text


def make_skills() -> list[str]:
    out = SHARED / "skills"
    if out.exists():
        shutil.rmtree(out)
    ids = []
    for src in sorted((OPENCODE / "skills").glob("*/SKILL.md")):
        sid = src.parent.name
        text = src.read_text(encoding="utf-8")
        m = re.match(r"^---\n(.*?)\n---\n(.*)$", text, re.S)
        fm, body = yaml.safe_load(m.group(1)), m.group(2)
        for pattern, repl in SKILL_SUBS:
            body = re.sub(pattern, repl, body)
        desc = fm["description"]
        dest = out / sid
        dest.mkdir(parents=True)
        (dest / "SKILL.md").write_text(f"---\nname: {sid}\ndescription: {json.dumps(desc, ensure_ascii=False)}\n---\n{body}", encoding="utf-8")
        ids.append(sid)
    return ids


# ── 2. per-tool rendering ────────────────────────────────────────────────────────────────────────
def body(agent_id: str, subs: dict[str, str]) -> str:
    text = (SHARED / "agents" / f"{agent_id}.md").read_text(encoding="utf-8")
    for k, v in subs.items():
        text = text.replace("{{" + k + "}}", v)
    text = re.sub(r"\n?\{\{[A-Z_]+\}\}\n?", "\n", text)  # drop unused placeholders
    return text.strip() + "\n"


def frontmatter(fm: dict | str) -> str:
    if isinstance(fm, str):
        return fm.strip() + "\n"
    return yaml.safe_dump(fm, sort_keys=False, allow_unicode=True, width=1000).strip() + "\n"


def toml_value(v) -> str:
    if isinstance(v, bool):
        return "true" if v else "false"
    if isinstance(v, (int, float)):
        return str(v)
    if isinstance(v, list):
        return "[" + ", ".join(toml_value(x) for x in v) + "]"
    if isinstance(v, dict):
        return "{ " + ", ".join(f"{k} = {toml_value(x)}" for k, x in v.items()) + " }"
    return json.dumps(str(v), ensure_ascii=False)


def render_commands(cfg: dict, base: Path) -> list[Path]:
    """Render _shared/commands.yaml into one tool's command format."""
    cmds = yaml.safe_load((SHARED / "commands.yaml").read_text(encoding="utf-8"))["commands"]
    fmt, out = cfg["format"], base / cfg["out"]
    roles = cfg.get("roles", {})
    written = []
    for cid, c in cmds.items():
        if cid in cfg.get("skip", []):
            continue
        role = roles.get(c["role"], c["role"])
        delegate = cfg.get("role_text", {}).get(c["role"]) or cfg.get("delegate", "").replace("{{ROLE}}", role)
        ctx = c.get("context")
        args_token = cfg.get("args_token", "$ARGUMENTS")
        text = c["body"].replace("{{ARGS}}", args_token).strip()
        if fmt == "claude":
            fm = {"description": c["description"]}
            if c.get("args"):
                fm["argument-hint"] = c["args"]
            if c.get("cheap") and cfg.get("cheap_model"):
                fm["model"] = cfg["cheap_model"]
            if ctx and cfg.get("context_allowed_tools"):
                fm["allowed-tools"] = cfg["context_allowed_tools"]
            parts = [text]
            if ctx:
                parts.append(f"Context (collected before this prompt):\n!`{ctx}`")
            if delegate and role != "main":
                parts.append(delegate)
            dest = out / f"{cid}.md"
            dest.parent.mkdir(parents=True, exist_ok=True)
            dest.write_text(f"---\n{frontmatter(fm)}---\n\n" + "\n\n".join(parts) + "\n", encoding="utf-8")
        elif fmt == "vscode":
            fm = {"description": c["description"], "agent": role}
            if c.get("args"):
                fm["argument-hint"] = c["args"]
            if c.get("cheap") and cfg.get("cheap_model"):
                fm["model"] = cfg["cheap_model"]
            parts = [text]
            if ctx:
                parts.append(f"First gather context with the terminal (read-only): `{ctx}`")
            dest = out / f"{cid}.prompt.md"
            dest.parent.mkdir(parents=True, exist_ok=True)
            dest.write_text(f"---\n{frontmatter(fm)}---\n\n" + "\n\n".join(parts) + "\n", encoding="utf-8")
        elif fmt == "cline":
            lines = [f"# /{cid}.md — {c['description']}", "", text.replace(args_token, "the target Murpheux gave with the command"), ""]
            steps = []
            if ctx:
                steps.append(f"Run this read-only command with `execute_command` and use its output: `{ctx}`")
            if delegate:
                steps.append(delegate)
            if steps:
                lines += ["## Steps", ""] + [f"{i}. {s}" for i, s in enumerate(steps, 1)] + [""]
            dest = out / f"{cid}.md"
            dest.parent.mkdir(parents=True, exist_ok=True)
            dest.write_text("\n".join(lines), encoding="utf-8")
        elif fmt == "skill":
            sid = cfg.get("prefix", "") + cid
            hint = cfg.get("invoke_hint", "`$" + "{sid}`").replace("{sid}", sid)
            parts = [f"# {sid}", "", f"Workflow skill (invoke explicitly, e.g. {hint}). Treat the user's words after the skill name as the target.", "", text.replace(args_token, "the user's target")]
            if ctx:
                parts += ["", f"Start by running this read-only command and use its output as context: `{ctx}`"]
            if delegate and role != "main":
                parts += ["", delegate]
            dest = out / sid / "SKILL.md"
            dest.parent.mkdir(parents=True, exist_ok=True)
            dest.write_text(f"---\nname: {sid}\ndescription: {json.dumps(c['description'], ensure_ascii=False)}\n---\n\n" + "\n".join(parts) + "\n", encoding="utf-8")
            if cfg.get("codex_explicit_only"):
                (dest.parent / "agents").mkdir(exist_ok=True)
                (dest.parent / "agents" / "openai.yaml").write_text("policy:\n  allow_implicit_invocation: false\n", encoding="utf-8")
        else:
            raise SystemExit(f"unknown command format {fmt}")
        written.append(dest)
    return written


def render_tool(tool: str, template: str) -> list[Path]:
    spec = yaml.safe_load((SHARED / "tools" / f"{tool}.yaml").read_text(encoding="utf-8"))
    if spec.get("placeholders_from"):  # share one instructions render between tools (e.g. ~/.copilot)
        other = yaml.safe_load((SHARED / "tools" / f"{spec['placeholders_from']}.yaml").read_text(encoding="utf-8"))
        for key in ("placeholders", "router_subs", "body_subs"):
            spec[key] = {**other.get(key, {}), **spec.get(key, {})}
    base = ROOT / tool
    written: list[Path] = []

    # instructions file(s)
    router_inline = re.sub(r"(?m)^(#+) ", r"#\1 ", body("router", {**spec.get("body_subs", {}), **spec.get("router_subs", {})}))
    router_inline = re.sub(r"^# Router / Orchestrator\n+", "", router_inline.replace("## Router / Orchestrator", "# Router / Orchestrator"))
    for inst in spec.get("instructions", []):
        text = template
        for k, v in spec["placeholders"].items():
            text = text.replace("{{" + k + "}}", v.strip().replace("@@ROUTER@@", router_inline.strip()))
        if "{{" in text:
            raise SystemExit(f"{tool}: unresolved placeholders {set(re.findall(r'{{[A-Z_]+}}', text))}")
        if inst.get("header"):
            text = inst["header"].rstrip() + "\n\n" + text
        dest = base / inst["out"]
        dest.parent.mkdir(parents=True, exist_ok=True)
        dest.write_text(text, encoding="utf-8")
        written.append(dest)

    # skills
    for sk_out in spec.get("skills_out", []):
        dest = base / sk_out
        if dest.exists():
            shutil.rmtree(dest)
        shutil.copytree(SHARED / "skills", dest)
        written.append(dest)

    # agents
    for ag in spec.get("agents", []):
        dest = base / ag["out"]
        dest.parent.mkdir(parents=True, exist_ok=True)
        content = body(ag.get("body", ag["id"]), {**spec.get("body_subs", {}), **(spec.get("router_subs", {}) if ag.get("body", ag["id"]) == "router" else {}), **ag.get("subs", {})})
        if ag.get("prepend"):
            content = ag["prepend"].rstrip() + "\n\n" + content
        if ag.get("append"):
            content = content.rstrip() + "\n\n" + ag["append"].strip() + "\n"
        if ag.get("toml") is not None:  # Codex custom agent: keys + developer_instructions literal string
            if "'''" in content:
                raise SystemExit(f"{ag['id']}: body contains ''' which breaks a TOML literal string")
            lines = [f"# {dest.name} — generated by _shared/build.py from _shared/agents/{ag.get('body', ag['id'])}.md"]
            for k, v in ag["toml"].items():
                lines.append(f"{k} = {toml_value(v)}")
            lines.append(f"developer_instructions = '''\n{content}'''")
            dest.write_text("\n".join(lines) + "\n", encoding="utf-8")
        elif ag.get("json") is not None:  # Kiro CLI agent: JSON config, system prompt inline as "prompt"
            obj = {**ag["json"], "prompt": content.strip()}
            dest.write_text(json.dumps(obj, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
        else:
            fm = ag.get("frontmatter")
            dest.write_text((f"---\n{frontmatter(fm)}---\n\n" if fm else "") + content, encoding="utf-8")
        written.append(dest)

    # commands / workflows / command-skills
    if spec.get("commands"):
        written += render_commands(spec["commands"], base)

    # guard hook
    for g in spec.get("guard_out", []):
        dest = base / g
        dest.mkdir(parents=True, exist_ok=True)
        for f in ("guard.py", "guardrails.json"):
            shutil.copy2(SHARED / "guardrails" / f, dest / f)
        written.append(dest)

    # on-demand skill loaders (tools without native skills, e.g. Aider /load files)
    if spec.get("skill_cmds_out"):
        dest = base / spec["skill_cmds_out"]
        dest.mkdir(parents=True, exist_ok=True)
        for sk in sorted((SHARED / "skills").iterdir()):
            (dest / f"skill-{sk.name}.cmds").write_text(
                f"# /load this file to add the '{sk.name}' skill to the chat as read-only context\n"
                f"/read-only {spec['skill_cmds_prefix']}/{sk.name}/SKILL.md\n", encoding="utf-8")
        written.append(dest)

    # files shared verbatim with another tool folder (single source, e.g. ~/.copilot core)
    for cf in spec.get("copy_files", []):
        src, dest = ROOT / cf["from"], base / cf["to"]
        dest.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(src, dest)
        written.append(dest)

    # installer library
    lib = base / "lib"
    lib.mkdir(parents=True, exist_ok=True)
    for f in ("install-lib.sh", "merge_json.py"):
        shutil.copy2(SHARED / f, lib / f)
    return written


def main(argv: list[str]) -> int:
    template = make_template()
    skills = make_skills()
    print(f"template: {len(template)} chars · skills: {len(skills)}")
    tools = argv or sorted(p.stem for p in (SHARED / "tools").glob("*.yaml"))
    for t in tools:
        files = render_tool(t, template)
        print(f"{t}: rendered {len(files)} item(s)")
    # Files authored from Windows arrive with CRLF, which breaks shebangs/hooks on macOS/Linux.
    import subprocess
    subprocess.run([sys.executable, str(SHARED / "normalize_eol.py"), str(ROOT)], check=True, stdout=subprocess.DEVNULL)
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
