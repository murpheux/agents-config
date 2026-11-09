#!/usr/bin/env python3
"""Point ~/.grok/user-settings.json at Agentgateway and remove the stored plaintext apiKey.

grok-cli (utils/settings-manager.js) reads GROK_API_KEY before the file's apiKey and GROK_BASE_URL
before baseURL; the `grok` wrapper sets both, so the file must not keep a key. `models` is REPLACED
(not unioned) so the /models picker lists only gateway ids, and settingsVersion stays >= 2 so grok-cli's
migration doesn't prepend its x.ai model list again. Not lib/merge_json.py: that leaves a .bak copy
(with the old key) next to the file. Writes 0600 atomically; prints key NAMES only, never values.

usage: configure-settings.py <grok-home> <fragment.json> [--dry-run]
"""
from __future__ import annotations

import json
import os
import sys
from pathlib import Path

REMOVE = ("apiKey",)


def main() -> int:
    args = [a for a in sys.argv[1:] if a != "--dry-run"]
    if len(args) != 2:
        print(__doc__, file=sys.stderr)
        return 2
    target = Path(args[0]).expanduser() / "user-settings.json"
    fragment = {k: v for k, v in json.loads(Path(args[1]).read_text()).items() if not k.startswith("_")}
    current = json.loads(target.read_text()) if target.exists() and target.read_text().strip() else {}
    removed = [k for k in REMOVE if k in current]
    merged = {k: v for k, v in current.items() if k not in REMOVE}
    merged.update(fragment)
    merged["settingsVersion"] = max(int(current.get("settingsVersion", 0) or 0), int(fragment.get("settingsVersion", 2)))
    changed = sorted(k for k in merged if current.get(k) != merged[k])
    if "--dry-run" in sys.argv:
        print(f"DRY: {target}: set {', '.join(changed) or 'nothing'}; remove {', '.join(removed) or 'nothing'}")
        return 0
    target.parent.mkdir(parents=True, exist_ok=True)
    tmp = target.with_suffix(".json.tmp")
    tmp.write_text(json.dumps(merged, indent=2) + "\n", encoding="utf-8")
    os.chmod(tmp, 0o600)
    tmp.replace(target)
    print(f"{target}: set {', '.join(changed) or 'nothing'}; removed {', '.join(removed) or 'nothing'}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
