---
name: bash
description: "Writing or reviewing bash/zsh scripts for macOS and Linux — strict mode, portability (BSD vs GNU), safety, shellcheck/shfmt"
---

# Bash / zsh scripts

## Skeleton
```bash
#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'
readonly SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

log() { printf '%s %s\n' "$(date -u +%FT%TZ)" "$*" >&2; }
die() { log "ERROR: $*"; exit 1; }
cleanup() { rm -f -- "${tmp:-}"; }
trap cleanup EXIT
trap 'die "line $LINENO: $BASH_COMMAND"' ERR

usage() { echo "usage: ${0##*/} [-n] <target>"; }
main() {
  local dry_run=false
  while getopts ':nh' opt; do case $opt in n) dry_run=true ;; h) usage; exit 0 ;; *) usage; exit 2 ;; esac; done
  shift $((OPTIND - 1)); [[ $# -eq 1 ]] || { usage; exit 2; }
  tmp="$(mktemp)"
  # work
}
main "$@"
```

## Rules
- File names `kebab-case.sh`; quote every expansion; `[[ ]]` over `[ ]`; `$(...)` not backticks; `local` in functions.
- Portability: macOS ships BSD tools + bash 3.2 — use `#!/usr/bin/env bash` with Homebrew bash 5, or stay POSIX; beware `sed -i ''` vs `sed -i`, `date`, `readlink -f`, `grep -P`.
- Dry-run flag for anything destructive; confirm before deleting; never `rm -rf "$VAR/"` without `: "${VAR:?}"` guard.
- Secrets from env / `op run --env-file` — never as CLI args (visible in `ps`) and never echoed; `set +x` around sensitive sections.
- Don't pipe remote scripts to a shell; download, verify checksum, then execute.
- Keep scripts out of YAML/manifests — call them from `scripts/`.

## Validate
`shellcheck -x script.sh` · `shfmt -d -i 2 -ci script.sh` (read-only, safe to auto-approve).
