#!/usr/bin/env python3
"""Offline validator for all generated agent configs (no agent binaries needed).

Checks: JSON/JSONC/TOML/YAML parse, Markdown frontmatter, skill spec (name == dir, description),
Codex Starlark rules (executed with stubs; match/not_match examples verified), guard self-test,
and unresolved {{PLACEHOLDERS}}.
"""
from __future__ import annotations

import json
import re
import shlex
import subprocess
import sys
import tomllib
from pathlib import Path

import yaml

ROOT = Path(__file__).resolve().parent.parent
errors: list[str] = []
counts: dict[str, int] = {}


def bump(k):
    counts[k] = counts.get(k, 0) + 1


def strip_jsonc(s: str) -> str:
    out, i, n, in_str = [], 0, len(s), False
    while i < n:
        c = s[i]
        if in_str:
            out.append(c)
            if c == "\\":
                out.append(s[i + 1]); i += 2; continue
            if c == '"':
                in_str = False
            i += 1; continue
        if c == '"':
            in_str = True; out.append(c); i += 1; continue
        if s.startswith("//", i):
            while i < n and s[i] != "\n":
                i += 1
            continue
        if s.startswith("/*", i):
            i = s.index("*/", i) + 2; continue
        out.append(c); i += 1
    return re.sub(r",(\s*[}\]])", r"\1", "".join(out))


def check_rules(path: Path):
    rules = []

    def prefix_rule(pattern, decision="allow", justification="", match=(), not_match=()):
        if decision not in ("allow", "prompt", "forbidden"):
            errors.append(f"{path.name}: bad decision {decision}")
        rules.append(pattern)

        def matches(cmd):
            argv = shlex.split(cmd)
            if len(argv) < len(pattern):
                return False
            return all((a in p) if isinstance(p, list) else a == p for a, p in zip(argv, pattern))

        for m in match:
            if not matches(m):
                errors.append(f"{path.name}: example {m!r} does not match {pattern}")
        for m in not_match:
            if matches(m):
                errors.append(f"{path.name}: not_match example {m!r} matches {pattern}")

    def host_executable(**_):
        pass

    def network_rule(**_):
        pass

    try:
        exec(compile(path.read_text(), str(path), "exec"), {"prefix_rule": prefix_rule, "host_executable": host_executable, "network_rule": network_rule})
    except Exception as e:  # noqa: BLE001
        errors.append(f"{path}: {e}")
    counts["codex rules"] = counts.get("codex rules", 0) + len(rules)


def frontmatter(path: Path):
    text = path.read_text(encoding="utf-8")
    m = re.match(r"^---\n(.*?)\n---\n", text, re.S)
    if not m:
        return None, text
    return yaml.safe_load(m.group(1)), text[m.end():]


for p in sorted(ROOT.rglob("*")):
    if not p.is_file() or "/_shared/" in str(p) or "/reports/" in str(p) or "/.git/" in str(p):
        continue
    rel = p.relative_to(ROOT)
    try:
        text = p.read_text(encoding="utf-8")
    except UnicodeDecodeError:
        continue
    if "\r\n" in text:
        errors.append(f"{rel}: CRLF line endings (breaks shebangs/hooks on macOS/Linux)")
    if "{{" in text and re.search(r"\{\{[A-Z_]+\}\}", text):
        errors.append(f"{rel}: unresolved placeholder {re.findall(r'{{[A-Z_]+}}', text)[:3]}")
    try:
        if p.suffix == ".json" or p.name.endswith(".jsonc"):
            json.loads(strip_jsonc(text)); bump("json")
        elif p.suffix == ".toml":
            tomllib.loads(text); bump("toml")
        elif p.suffix in (".yml", ".yaml"):
            if text.startswith("---\n") and "/.cline/agents/" in str(p):
                fm, body = frontmatter(p)  # Cline agent: YAML frontmatter + Markdown body
                for k in ("name", "description", "providerId", "modelId"):
                    if not fm or not fm.get(k):
                        errors.append(f"{rel}: Cline agent missing '{k}'")
                if not body.strip():
                    errors.append(f"{rel}: Cline agent has empty body")
                bump("cline agents")
            else:
                list(yaml.safe_load_all(text)); bump("yaml")
        elif p.suffix == ".rules":
            check_rules(p)
        elif p.suffix == ".md":
            fm, _ = frontmatter(p)
            if fm is not None:
                bump("md+frontmatter")
                if p.name == "SKILL.md" and "/opencode/.config/" not in str(p):  # OpenCode uses display names; ids come from the path
                    if fm.get("name") != p.parent.name:
                        errors.append(f"{rel}: skill name {fm.get('name')!r} != folder {p.parent.name!r}")
                    if not re.fullmatch(r"[a-z0-9]+(-[a-z0-9]+)*", str(fm.get("name", ""))) or len(str(fm.get("name"))) > 64:
                        errors.append(f"{rel}: skill name violates spec")
                    if not fm.get("description") or len(fm["description"]) > 1024:
                        errors.append(f"{rel}: skill description missing/too long")
                    bump("skills")
    except Exception as e:  # noqa: BLE001
        errors.append(f"{rel}: {type(e).__name__}: {e}")

# Kiro agents: JSON with name + prompt; Antigravity instruction files must stay <= 24 KB
for p in sorted(ROOT.rglob("*")):
    if not p.is_file() or "/_shared/" in str(p) or "/.git/" in str(p):
        continue
    rel = p.relative_to(ROOT)
    if p.suffix == ".json" and "/.kiro/agents/" in str(p):
        try:
            d = json.loads(p.read_text(encoding="utf-8"))
            for k in ("name", "prompt"):
                if not isinstance(d.get(k), str) or not d[k].strip():
                    errors.append(f"{rel}: Kiro agent missing '{k}'")
            bump("kiro agents")
        except Exception as e:  # noqa: BLE001
            errors.append(f"{rel}: {type(e).__name__}: {e}")
    if p.name in ("GEMINI.md", "AGENTS.md") and str(rel).startswith("antigravity/") and p.stat().st_size > 24 * 1024:
        errors.append(f"{rel}: Antigravity instructions {p.stat().st_size} B exceed 24 KB")

# guard self-test in every tool that ships it
for g in sorted(ROOT.glob("*/**/guard.py")):
    if "_shared" in str(g):
        continue
    r = subprocess.run([sys.executable, str(g), "--self-test"], capture_output=True, text=True)
    bump("guard copies")
    if r.returncode:
        errors.append(f"{g.relative_to(ROOT)}: self-test failed\n{r.stdout}{r.stderr}")

print(" · ".join(f"{k}={v}" for k, v in sorted(counts.items())))
for e in errors:
    print("ERROR", e)
print("OK" if not errors else f"{len(errors)} error(s)")
sys.exit(1 if errors else 0)
