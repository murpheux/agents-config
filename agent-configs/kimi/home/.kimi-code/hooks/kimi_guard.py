#!/usr/bin/env python3
"""Kimi Code CLI adapter for the shared guard (guard.py + guardrails.json are copied byte-for-byte from
_shared/guardrails into this directory by _shared/build.py - never edit those copies).

SKELETON: the stdin event shape below is a Claude-style assumption from Phase 0 research - verify it.
stdin : {"tool_name"|"toolName": str, "tool_input"|"input": {...}}
exit 0 = allow; exit 2 + reason on stderr = block (assumed hook protocol - verify)
"""
from __future__ import annotations

import json
import sys
from pathlib import Path

sys.dont_write_bytecode = True
sys.path.insert(0, str(Path(__file__).resolve().parent))


def decide(event: dict) -> tuple[str, str]:
    import guard  # noqa: PLC0415 - shared guard, same directory (absent until `make build`)
    tool = str(event.get("tool_name") or event.get("toolName") or "").lower()
    args = event.get("tool_input") or event.get("input") or {}
    return guard.evaluate({"tool_name": tool, "tool_input": args if isinstance(args, dict) else {}})


def main() -> int:
    try:
        decision, reason = decide(json.loads(sys.stdin.read() or "{}"))
    except Exception as exc:  # noqa: BLE001 - never fail open
        decision, reason = "deny", f"guard error: {exc}"
    if decision == "allow":
        return 0
    print(f"guardrails: {decision}: {reason}", file=sys.stderr)
    return 2  # block (ask is treated as block until the tool's confirm protocol is verified)


if __name__ == "__main__":
    sys.exit(main())
