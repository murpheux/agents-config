"""Tau guardrails extension — the shared guard (``~/.tau/guard/guard.py`` + ``guardrails.json``,
copied byte-for-byte from ``_shared/guardrails`` by ``_shared/build.py``) as a ``tool_call`` hook.

Tau has no permission rules; this is its enforcement layer, the same rule set every other tool in
this repo uses. Tau blocks the call when a hook raises, and this module also blocks every guarded
tool (bash/read/write/edit) if the guard can't be loaded, so it fails closed. ``ask``-severity rules (git push, reset
--hard, swarm removals, destructive SQL) are blocked too: Tau has no approval prompt, so the agent
is told to hand the command to Murpheux instead.
"""

from __future__ import annotations

import importlib.util
import os
from pathlib import Path
from typing import Any

from tau_coding.extensions import ExtensionAPI, ToolCallHookEvent, ToolCallHookResult

_TAU_HOME = Path(os.environ.get("TAU_HOME") or Path.home() / ".tau").expanduser()
_GUARD_PATH = _TAU_HOME / "guard" / "guard.py"
_GUARDED = {"bash", "read", "write", "edit"}  # without the guard none of these can be checked


def _load_guard() -> Any:
    spec = importlib.util.spec_from_file_location("tau_shared_guard", _GUARD_PATH)
    if spec is None or spec.loader is None:
        raise ImportError(f"cannot load {_GUARD_PATH}")
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def _decide(guard: Any, event: ToolCallHookEvent) -> tuple[str, str]:
    args = event.arguments
    if event.tool_name == "bash":
        return guard.check_command(str(args.get("command", "")))
    if event.tool_name == "read":
        return guard.check_path(str(args.get("path", "")))
    if event.tool_name in {"write", "edit"}:
        return guard.check_path(str(args.get("path", "")), write=True)
    return "allow", ""


def setup(tau: ExtensionAPI) -> None:
    try:
        guard = _load_guard()
        load_error = None
    except Exception as exc:  # noqa: BLE001 — any failure must fail closed below
        guard, load_error = None, exc

    @tau.on("tool_call")
    def _guard(event: ToolCallHookEvent, _ctx: object) -> ToolCallHookResult | None:
        if guard is None:
            if event.tool_name in _GUARDED:
                return ToolCallHookResult(block=True, reason=f"guardrails unavailable ({load_error}); reinstall the Tau config")
            return None
        decision, reason = _decide(guard, event)
        if decision == "deny":
            return ToolCallHookResult(block=True, reason=f"Blocked by guardrails {reason}")
        if decision == "ask":
            return ToolCallHookResult(
                block=True,
                reason=f"Needs Murpheux's approval {reason} — present the exact command and let him run it",
            )
        return None
