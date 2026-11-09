#!/usr/bin/env python3
"""Hermes ``pre_tool_call`` shell hook → the shared guard (``~/.hermes/guard/guard.py`` + ``guardrails.json``,
copied byte-for-byte from ``_shared/guardrails`` by ``_shared/build.py``).

Wire protocol (website/docs/user-guide/features/hooks.md "Shell Hooks", agent/shell_hooks.py):
stdin  {"hook_event_name": "pre_tool_call", "tool_name": ..., "tool_input": {...}, ...}
stdout {"action": "block", "message": ...}  — or "{}" to allow.

Shell hooks can only ``block``/``modify`` (no ``approve``), so the guard's ``ask`` rules (git push, reset
--hard, swarm removals, destructive SQL) are blocked with a hand-off message. Every internal error blocks
too, and config.yaml sets ``fail_closed: true`` so a crash/timeout/missing script blocks as well.
Stdlib only.
"""
from __future__ import annotations

import importlib.util
import json
import os
import re
import sys
from pathlib import Path

_HOME = Path(os.environ.get("HERMES_HOME") or Path.home() / ".hermes").expanduser()
_GUARD_PATH = _HOME / "guard" / "guard.py"
# Same header grammar as tools/file_tools.py (_V4A_SINGLE_HEADER_RE / _V4A_MOVE_HEADER_RE).
_V4A_SINGLE = re.compile(r"^(\*\*\*\s*(Update|Add|Delete)\s+File:\s*)(.+)$", re.MULTILINE)
_V4A_MOVE = re.compile(r"^(\*\*\*\s*Move\s+File:\s*)(.+?)\s*->\s*(.+)$", re.MULTILINE)
_RANK = {"allow": 0, "ask": 1, "deny": 2}


def _load_guard():
    spec = importlib.util.spec_from_file_location("hermes_shared_guard", _GUARD_PATH)
    if spec is None or spec.loader is None:
        raise ImportError(f"cannot load {_GUARD_PATH}")
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def _patch_paths(args: dict) -> list[str]:
    paths = [str(args["path"])] if args.get("path") else []
    text = str(args.get("patch") or "")
    paths += [m.group(3).strip() for m in _V4A_SINGLE.finditer(text)]
    paths += [g.strip() for m in _V4A_MOVE.finditer(text) for g in (m.group(2), m.group(3))]
    return paths


def evaluate(guard, tool: str, args: dict) -> tuple[str, str]:
    """Worst (decision, reason) over everything the call touches."""
    if tool == "terminal":
        checks = [guard.check_command(str(args.get("command", "")))]
    elif tool in ("read_file", "search_files"):
        checks = [guard.check_path(str(args.get("path", "")))]
    elif tool == "write_file":
        checks = [guard.check_path(str(args.get("path", "")), write=True)]
    elif tool == "patch":
        checks = [guard.check_path(p, write=True) for p in _patch_paths(args)] or [("allow", "")]
    else:
        return "allow", ""
    return max(checks, key=lambda c: _RANK.get(c[0], 2))


def _block(message: str) -> int:
    print(json.dumps({"action": "block", "message": message}))
    return 0


def main() -> int:
    try:
        payload = json.loads(sys.stdin.read() or "{}")
        tool = str(payload.get("tool_name") or "")
        args = payload.get("tool_input") or {}
        if not isinstance(args, dict):
            raise ValueError("tool_input is not an object")
    except Exception as exc:  # noqa: BLE001 — unreadable payload: fail closed
        return _block(f"guardrails: unreadable hook payload ({exc})")
    try:
        guard = _load_guard()
    except Exception as exc:  # noqa: BLE001
        return _block(f"guardrails unavailable ({exc}); reinstall the Hermes config")
    try:
        decision, reason = evaluate(guard, tool, args)
    except Exception as exc:  # noqa: BLE001
        return _block(f"guardrails error ({exc})")
    if decision == "deny":
        return _block(f"Blocked by guardrails {reason}")
    if decision == "ask":
        return _block(f"Needs Murpheux's approval {reason} — present the exact command and let him run it")
    print("{}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
