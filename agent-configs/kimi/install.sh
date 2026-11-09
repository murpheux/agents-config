#!/usr/bin/env bash
# Install the Kimi Code CLI configuration into ${KIMI_CODE_HOME:-$HOME/.kimi-code} (macOS or Linux/WSL). Fully self-contained:
#   - syncs the installer helpers (install-lib.sh, merge_json.py, normalize_eol.py) from ../_shared into lib/
#   - copies the shared guard (guard.py + guardrails.json) from ../_shared/guardrails next to the adapter
#   - merges/installs the config, wrapper and agents; hooks the wrapper into ~/.zshrc (SKIP_SHELL_RC=1 to skip)
#   - runs the guard self-test; copies ONLY config files, never runtime state (sessions, caches, credentials)
# Everything it replaces is backed up to ~/.agent-config-backups/kimi-<timestamp>/. Safe to re-run.
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

SRC="$HERE/home/.kimi-code"
DEST="${KIMI_CODE_HOME:-$HOME/.kimi-code}"
[[ -f "$SRC/AGENTS.md" ]] || die "source config not found at $SRC (run: make build)"
need kimi "Kimi Code CLI is not installed - config is still staged, install the CLI to use it"
need python3 "required by the guardrails hook (it runs the shared guard)"
need op      "1Password CLI - the wrapper reads the gateway key at launch"

log "kimi config -> $DEST ($(os_kind))"
CONFIG_FILES=(AGENTS.md kimi-env.sh hooks/kimi_guard.py)
for rel in "${CONFIG_FILES[@]}"; do install_file kimi "$SRC/$rel" "$DEST/$rel"; done
for d in agents skills commands plugins; do
  [[ -d "$SRC/$d" ]] || continue
  run mkdir -p "$DEST/$d"
  while IFS= read -r -d '' f; do
    [[ "$(basename "$f")" == .gitkeep ]] && continue
    install_file kimi "$f" "$DEST/${f#"$SRC"/}"
  done < <(find "$SRC/$d" -type f -print0)
done
# config.toml is TOML (no safe key-level merge): replaced, original kept in the backup tree.
[[ -f "$DEST/config.toml" ]] && ! cmp -s "$SRC/config.toml" "$DEST/config.toml" && warn "replacing your config.toml (backed up) - re-add custom providers/models from the backup"
install_file kimi "$SRC/config.toml" "$DEST/config.toml"

install_guard kimi "$DEST/hooks"

ensure_shell_source kimi "$DEST/kimi-env.sh"

if [[ "$DRY_RUN" != 1 ]]; then
  python3 "$DEST/hooks/guard.py" --self-test >/dev/null && log "guard self-test passed" || die "guard self-test failed"
fi

log "kimi install complete. Smoke test: open a new shell, run kimi with a one-shot prompt via the gateway model."
