#!/usr/bin/env python3
"""Claude Code status line: model · effort · session cost · context use. Reads session JSON on stdin."""
import json
import sys

try:
    s = json.load(sys.stdin)
except Exception:
    print("claude")
    sys.exit(0)

model = (s.get("model") or {}).get("display_name") or "?"
effort = ((s.get("effort") or {}).get("level")) or ""
cost = (s.get("cost") or {}).get("total_cost_usd")
ctx = (s.get("context_window") or {}).get("used_percentage")
agent = (s.get("agent") or {}).get("name") if isinstance(s.get("agent"), dict) else s.get("agent")

parts = [f"🤖 {model}" + (f" · {effort}" if effort else "")]
if agent:
    parts.append(f"agent:{agent}")
if cost is not None:
    parts.append(f"${cost:.2f}")
if ctx is not None:
    warn = " ⚠" if ctx >= 70 else ""
    parts.append(f"ctx {ctx:.0f}%{warn}")
print("  │  ".join(parts))
