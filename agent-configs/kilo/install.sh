#!/usr/bin/env bash
# Install the Kilo Code CLI configuration into ${KILO_CONFIG_DIR:-$HOME/.config/kilo} (macOS or Linux/WSL). Fully self-contained:
#   - syncs the installer helpers (install-lib.sh, merge_json.py, normalize_eol.py) from ../_shared into lib/
#   - copies the shared guard (guard.py + guardrails.json) from ../_shared/guardrails next to the adapter
#   - merges/installs the config, wrapper and agents; hooks the wrapper into ~/.zshrc (SKIP_SHELL_RC=1 to skip)
#   - runs the guard self-test; copies ONLY config files, never runtime state (sessions, caches, credentials)
# Everything it replaces is backed up to ~/.agent-config-backups/kilo-<timestamp>/. Safe to re-run.
#   ./install.sh              install            DRY_RUN=1 ./install.sh   preview
set -Eeuo pipefail
HERE="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

# Bootstrap helpers from the shared source (single copy) before sourcing them.
if [[ -d "$HERE/../_shared" ]]; then
  mkdir -p "$HERE/lib"
  for f in install-lib.sh merge_json.py normalize_eol.py; do
    [[ -f "$HERE/../_shared/$f" ]] && cp "$HERE/../_shared/$f" "$HERE/lib/$f"
  done
fi
[[ -f "$HERE/lib/install-lib.sh" ]] || { echo "xx lib/install-lib.sh missing and ../_shared not found" >&2; exit 1; }
source "$HERE/lib/install-lib.sh"

SRC="$HERE/home/.config/kilo"
DEST="${KILO_CONFIG_DIR:-$HOME/.config/kilo}"
[[ -f "$SRC/AGENTS.md" ]] || die "source config not found at $SRC (run: make build)"
need kilo "Kilo Code CLI is not installed - config is still staged, install the CLI to use it"
need python3 "required by the guardrails hook (it runs the shared guard)"
need op      "1Password CLI - the wrapper reads the gateway key at launch"

log "kilo config -> $DEST ($(os_kind))"
CONFIG_FILES=(AGENTS.md kilo-env.sh plugin/guardrails.ts guard/kilo_guard.py)
for rel in "${CONFIG_FILES[@]}"; do install_file kilo "$SRC/$rel" "$DEST/$rel"; done
for d in agents command skills; do
  [[ -d "$SRC/$d" ]] || continue
  run mkdir -p "$DEST/$d"
  while IFS= read -r -d '' f; do
    [[ "$(basename "$f")" == .gitkeep ]] && continue
    install_file kilo "$f" "$DEST/${f#"$SRC"/}"
  done < <(find "$SRC/$d" -type f -print0)
done
merge_config kilo "$SRC/kilo.jsonc" "$DEST/kilo.jsonc"

install_guard kilo "$DEST/guard"

ensure_shell_source kilo "$DEST/kilo-env.sh"

if [[ "$DRY_RUN" != 1 ]]; then
  python3 "$DEST/guard/guard.py" --self-test >/dev/null && log "guard self-test passed" || die "guard self-test failed"
fi

log "kilo install complete. Smoke test: open a new shell, run kilo with a one-shot prompt via the gateway model."
