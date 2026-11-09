#!/usr/bin/env python3
"""Merge the repo's config.fragment.yaml into a live Hermes home, and wire the guard hook's consent.

Run with Hermes' own interpreter (it has PyYAML). Steps — each prints names only, never values:
  1. config.yaml   deep-merge (your keys kept; scalars from the fragment win; skills.external_dirs is
                   unioned; any older guardrails hook entry is replaced, other hooks kept).
  2. shell-hooks-allowlist.json  add {"event": "pre_tool_call", "command": <exact hook command>} — the
                   documented manual allowlist; without it a non-TTY run (gateway/cron) silently skips
                   the hook, i.e. would fail OPEN (website/docs/user-guide/features/hooks.md "Consent model").
  3. .env          drop a plaintext AGENTGATEWAY_API_KEY line (key_cmd supplies the key now).

usage: configure-hermes.py <hermes-home> <fragment.yaml> --op <abs-op-path> [--dry-run]
"""
from __future__ import annotations

import argparse
import json
import os
import re
import sys
import tempfile
from pathlib import Path
from typing import Any

import yaml

HOOK_SCRIPT = "agent-hooks/guardrails-hook.py"
ENV_SCRUB = ("AGENTGATEWAY_API_KEY",)


def deep_merge(base: Any, frag: Any, path: str = "") -> Any:
    if isinstance(base, dict) and isinstance(frag, dict):
        out = dict(base)
        for key, value in frag.items():
            out[key] = deep_merge(base.get(key), value, f"{path}.{key}" if path else key)
        return out
    if path == "skills.external_dirs" and isinstance(base, list) and isinstance(frag, list):
        return base + [x for x in frag if x not in base]
    if path == "hooks.pre_tool_call" and isinstance(frag, list):
        kept = [h for h in (base or []) if not (isinstance(h, dict) and HOOK_SCRIPT in str(h.get("command", "")))]
        return kept + frag
    return frag


def atomic_write(path: Path, text: str, mode: int) -> None:
    fd, tmp = tempfile.mkstemp(dir=path.parent, prefix=f".{path.name}.")
    with os.fdopen(fd, "w", encoding="utf-8") as fh:
        fh.write(text)
    os.chmod(tmp, mode)
    os.replace(tmp, path)


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("home", type=Path)
    ap.add_argument("fragment", type=Path)
    ap.add_argument("--op", required=True, help="absolute path of the 1Password CLI")
    ap.add_argument("--dry-run", action="store_true")
    a = ap.parse_args()
    home = a.home.expanduser().resolve()
    hook_cmd = f"{sys.executable} {home / HOOK_SCRIPT}"
    frag_text = (a.fragment.read_text(encoding="utf-8")
                 .replace("__OP__", a.op).replace("__HERMES_HOME__", str(home)).replace("__HOOK_CMD__", hook_cmd))
    frag = yaml.safe_load(frag_text)

    cfg_path = home / "config.yaml"
    current = (yaml.safe_load(cfg_path.read_text(encoding="utf-8")) or {}) if cfg_path.exists() else {}
    merged = deep_merge(current, frag)
    changed = sorted(k for k in frag if current.get(k) != merged.get(k))
    print(f"config.yaml: {'would update' if a.dry_run else 'updated'} {', '.join(changed) or 'nothing'}")

    allow_path = home / "shell-hooks-allowlist.json"
    allow = json.loads(allow_path.read_text(encoding="utf-8")) if allow_path.exists() else {}
    approvals = allow.get("approvals") if isinstance(allow.get("approvals"), list) else []
    entry = {"event": "pre_tool_call", "command": hook_cmd}
    approvals = [x for x in approvals if not (isinstance(x, dict) and HOOK_SCRIPT in str(x.get("command", "")))] + [entry]
    print(f"shell-hooks-allowlist.json: guardrails hook {'would be ' if a.dry_run else ''}allowlisted")

    env_path = home / ".env"
    env_lines = env_path.read_text(encoding="utf-8").splitlines(keepends=True) if env_path.exists() else []
    rx = re.compile(r"^\s*(export\s+)?(" + "|".join(ENV_SCRUB) + r")\s*=")
    kept = [ln for ln in env_lines if not rx.match(ln)]
    removed = sorted({rx.match(ln).group(2) for ln in env_lines if rx.match(ln)})
    print(f".env: {('would remove ' if a.dry_run else 'removed ') + ', '.join(removed) if removed else 'no plaintext gateway key'}")

    if a.dry_run:
        return 0
    mode = cfg_path.stat().st_mode & 0o777 if cfg_path.exists() else 0o600
    atomic_write(cfg_path, yaml.safe_dump(merged, sort_keys=False, allow_unicode=True), mode)
    allow["approvals"] = approvals
    atomic_write(allow_path, json.dumps(allow, indent=2, sort_keys=True) + "\n", 0o600)
    if removed:
        atomic_write(env_path, "".join(kept), 0o600)
    return 0


if __name__ == "__main__":
    sys.exit(main())
