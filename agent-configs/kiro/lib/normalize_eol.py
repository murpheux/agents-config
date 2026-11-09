#!/usr/bin/env python3
"""Normalize CRLF → LF in text files under the given roots (skips binaries, .git, node_modules).
usage: normalize_eol.py [--check] ROOT...
"""
import sys
from pathlib import Path

SKIP_DIRS = {".git", "node_modules"}
BINARY_EXT = {".pdf", ".png", ".jpg", ".jpeg", ".gif", ".webp", ".zip", ".db", ".ico"}


def main(argv):
    check = "--check" in argv
    roots = [Path(a).expanduser() for a in argv if a != "--check"]
    crlf, total = [], 0
    for root in roots:
        for p in root.rglob("*"):
            if not p.is_file() or p.suffix.lower() in BINARY_EXT or any(part in SKIP_DIRS for part in p.parts):
                continue
            data = p.read_bytes()
            if b"\0" in data[:4096]:
                continue
            total += 1
            if b"\r\n" in data:
                crlf.append(p)
                if not check:
                    p.write_bytes(data.replace(b"\r\n", b"\n"))
    verb = "need fixing" if check else "normalized"
    print(f"{len(crlf)} of {total} text files {verb}")
    for p in crlf[:8]:
        print("  ", p)
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
