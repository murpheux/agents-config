#!/usr/bin/env python3
"""Deep-merge a JSON/JSONC fragment into a (possibly JSONC) settings file, preserving existing keys.

usage: merge_json.py <target.json> <fragment.json[c]> [--drop KEY.PATH ...] [--dry-run]
Objects merge recursively; arrays in the fragment are unioned with existing arrays (order kept);
scalars from the fragment win. Keys starting with "_" in the fragment are ignored (comments).
The target is backed up to <target>.bak-<timestamp> before writing. Comments in the target are not preserved.
"""
import json
import re
import shutil
import sys
import time
from pathlib import Path


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


def merge(base, frag):
    if isinstance(base, dict) and isinstance(frag, dict):
        for k, v in frag.items():
            if k.startswith("_"):
                continue
            base[k] = merge(base.get(k), v) if k in base else strip_private(v)
        return base
    if isinstance(base, list) and isinstance(frag, list):
        return base + [x for x in frag if x not in base]
    return strip_private(frag)


def strip_private(v):
    if isinstance(v, dict):
        return {k: strip_private(x) for k, x in v.items() if not k.startswith("_")}
    return v


def drop(obj, dotted):
    *parents, leaf = dotted.split(".")
    for p in parents:
        obj = obj.get(p) if isinstance(obj, dict) else None
        if obj is None:
            return
    if isinstance(obj, dict):
        obj.pop(leaf, None)


def main(argv):
    if len(argv) < 2:
        print(__doc__); return 2
    target, fragment = Path(argv[0]).expanduser(), Path(argv[1])
    drops = [argv[i + 1] for i, a in enumerate(argv) if a == "--drop" and i + 1 < len(argv)]
    dry = "--dry-run" in argv
    base = json.loads(strip_jsonc(target.read_text(encoding="utf-8"))) if target.exists() and target.read_text(encoding="utf-8").strip() else {}
    frag = json.loads(strip_jsonc(fragment.read_text(encoding="utf-8")))
    result = merge(base, frag)
    for d in drops:
        drop(result, d)
    text = json.dumps(result, indent=2, ensure_ascii=False) + "\n"
    if dry:
        print(text); return 0
    target.parent.mkdir(parents=True, exist_ok=True)
    if target.exists():
        shutil.copy2(target, target.with_name(target.name + time.strftime(".bak-%Y%m%d-%H%M%S")))
    target.write_text(text, encoding="utf-8")
    print(f"merged {fragment.name} into {target}")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
