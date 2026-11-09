#!/usr/bin/env python3
"""omp adapter for the shared guard (guard.py + guardrails.json in this directory, copied byte-for-byte
from _shared/guardrails by _shared/build.py — never edit those copies).

stdin : omp `tool_call` event JSON  {"toolName": str, "input": {...}}
stdout: {"decision": "allow"|"ask"|"deny", "reason": str}

guard.evaluate() already covers bash `command`, a top-level `path` and apply_patch "*** Begin Patch"
headers. omp-specific shapes it can't see (verified in omp 18.18.3's edit-tool schemas):
  edit/patch mode  {path, edits:[{op?, rename?, diff?}]}  → every `rename` target is a write
  edit/hashline|sloppy|apply_patch  {input: "<patch text>"} → paths inside the text are checked
  python {code-ish string}, notebook                       → command rules + protected paths in the text
Text scans are deliberately conservative: a protected path mentioned anywhere in patch/code text blocks.
"""
from __future__ import annotations

import json
import re
import sys
from pathlib import Path

sys.dont_write_bytecode = True
sys.path.insert(0, str(Path(__file__).resolve().parent))
import guard  # noqa: E402  (shared guard, same directory)

_TOKEN = re.compile(r"[\w.~$/\\-]*[./][\w.~$/\\-]+")
_LITERAL = re.compile(r"""'([^'\\\n]*(?:\\.[^'\\\n]*)*)'|"([^"\\\n]*(?:\\.[^"\\\n]*)*)\"""")  # shell commands in code live in string literals
_ORDER = {"deny": 2, "ask": 1, "allow": 0}


def _strings(value: object) -> list[str]:
    if isinstance(value, str):
        return [value]
    if isinstance(value, dict):
        return [s for v in value.values() for s in _strings(v)]
    if isinstance(value, list):
        return [s for v in value for s in _strings(v)]
    return []


def _scan_text(text: str, write: bool) -> list[tuple[str, str]]:
    return [guard.check_path(tok, write=write) for tok in _TOKEN.findall(text)]


def decide(event: dict) -> tuple[str, str]:
    tool = str(event.get("toolName") or "").lower()
    args = event.get("input") if isinstance(event.get("input"), dict) else {}
    decisions = [guard.evaluate({"tool_name": tool, "tool_input": args})]

    if tool == "edit":
        for e in args.get("edits") or []:
            if isinstance(e, dict) and isinstance(e.get("rename"), str):
                decisions.append(guard.check_path(e["rename"], write=True))
        if isinstance(args.get("input"), str):
            decisions += _scan_text(args["input"], write=True)
    elif tool in ("python", "notebook"):
        for text in _strings(args):
            decisions.append(guard.check_command(text))
            decisions += [guard.check_command(a or b) for a, b in _LITERAL.findall(text)]
            decisions += _scan_text(text, write=False)

    decision, reason = max(decisions, key=lambda d: _ORDER.get(d[0], 2))
    return decision, reason


def main() -> int:
    try:
        event = json.loads(sys.stdin.read() or "{}")
        decision, reason = decide(event)
    except Exception as exc:  # noqa: BLE001 — never fail open
        decision, reason = "deny", f"[guard-error] {exc}"
    print(json.dumps({"decision": decision, "reason": reason}))
    return 0


if __name__ == "__main__":
    sys.exit(main())
