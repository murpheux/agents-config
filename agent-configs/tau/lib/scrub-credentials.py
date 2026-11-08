#!/usr/bin/env python3
"""Remove credentials that this config now injects from 1Password at launch.

Tau checks credentials.json BEFORE a provider's api_key_env, so a stale plaintext key there would
silently win over the 1Password-sourced AGENTGATEWAY_API_KEY. catalog.toml no longer sets
credential_name for agentgateway; this deletes the leftover entry. Other entries (e.g. the
built-in llama.cpp key managed by /local) are left alone. Prints names only, never values.

usage: scrub-credentials.py <tau-home> [name ...] [--dry-run]      (default name: agentgateway)
"""
from __future__ import annotations

import json
import os
import sys
from pathlib import Path


def main() -> int:
    args = [a for a in sys.argv[1:] if a != "--dry-run"]
    if not args:
        print(__doc__, file=sys.stderr)
        return 2
    dry = "--dry-run" in sys.argv
    path = Path(args[0]).expanduser() / "credentials.json"
    names = args[1:] or ["agentgateway"]
    if not path.exists():
        print(f"{path}: not present — nothing to scrub")
        return 0
    data = json.loads(path.read_text(encoding="utf-8"))
    found = [n for n in names if n in data]
    if not found:
        print(f"{path}: no plaintext entries for {', '.join(names)}")
        return 0
    if dry:
        print(f"DRY: would remove {', '.join(found)} from {path}")
        return 0
    for n in found:
        del data[n]
    tmp = path.with_suffix(".json.tmp")
    tmp.write_text(json.dumps(data, indent=2) + "\n", encoding="utf-8")
    os.chmod(tmp, 0o600)
    tmp.replace(path)
    print(f"removed plaintext {', '.join(found)} from {path} (kept: {', '.join(sorted(data)) or 'none'})")
    return 0


if __name__ == "__main__":
    sys.exit(main())
