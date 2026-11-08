#!/usr/bin/env bash
# Shared installer helpers for ~/agent-configs/<tool>/install.sh
# Usage in an installer:  source "$(dirname "$0")/lib/install-lib.sh"
set -Eeuo pipefail

DRY_RUN="${DRY_RUN:-0}"
TS="$(date +%Y%m%d-%H%M%S)"
BACKUP_ROOT="${BACKUP_ROOT:-$HOME/.agent-config-backups}"

log()  { printf '\033[1;32m==>\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m!!\033[0m %s\n' "$*" >&2; }
die()  { printf '\033[1;31mxx\033[0m %s\n' "$*" >&2; exit 1; }
run()  { if [[ "$DRY_RUN" == 1 ]]; then echo "DRY: $*"; else "$@"; fi; }

os_kind() {
  case "$(uname -s)" in
    Darwin) echo macos ;;
    Linux)  grep -qi microsoft /proc/version 2>/dev/null && echo wsl || echo linux ;;
    *)      echo other ;;
  esac
}

ca_bundle() {
  case "$(os_kind)" in
    macos) echo /etc/ssl/cert.pem ;;
    *)     echo /etc/ssl/certs/ca-certificates.crt ;;
  esac
}

# backup_path <tool> <absolute-path>  — copies an existing file/dir into the backup tree once per run
backup_path() {
  local tool="$1" target="$2" dest
  [[ -e "$target" || -L "$target" ]] || return 0
  dest="$BACKUP_ROOT/$tool-$TS${target#"$HOME"}"
  run mkdir -p "$(dirname "$dest")"
  run cp -a "$target" "$dest"
  log "backed up $target → $dest"
}

# install_file <tool> <src> <dest> [mode]  — backup then copy, rendering __HOME__/__CA_BUNDLE__/__USER__ tokens
install_file() {
  local tool="$1" src="$2" dest="$3" mode="${4:-}"
  backup_path "$tool" "$dest"
  run mkdir -p "$(dirname "$dest")"
  if [[ "$DRY_RUN" == 1 ]]; then echo "DRY: render $src → $dest"; return; fi
  sed -e "s#__HOME__#${HOME}#g" -e "s#__CA_BUNDLE__#$(ca_bundle)#g" -e "s#__USER__#${USER:-$(id -un)}#g" "$src" > "$dest"
  [[ -n "$mode" ]] && chmod "$mode" "$dest"
  log "installed $dest"
}

# install_tree <tool> <src-dir> <dest-dir>  — mirror a directory (backup existing dest first)
install_tree() {
  local tool="$1" src="$2" dest="$3" f rel
  [[ -d "$src" ]] || die "missing $src"
  while IFS= read -r -d '' f; do
    rel="${f#"$src"/}"
    install_file "$tool" "$f" "$dest/$rel"
  done < <(find "$src" -type f -print0)
}

need() { command -v "$1" >/dev/null 2>&1 || warn "'$1' not found on PATH — $2"; }
