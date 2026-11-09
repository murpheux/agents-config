#!/usr/bin/env bash
# Install the Kiro CLI configuration into ${KIRO_HOME:-$HOME/.kiro} (macOS or Linux/WSL). Fully self-contained:
#   - syncs the installer helpers (install-lib.sh, merge_json.py, normalize_eol.py) from ../_shared into lib/
#   - copies the shared guard (guard.py + guardrails.json) from ../_shared/guardrails next to the adapter
#   - merges/installs the config, wrapper and agents; hooks the wrapper into ~/.zshrc (SKIP_SHELL_RC=1 to skip)
#   - runs the guard self-test; copies ONLY config files, never runtime state (sessions, caches, credentials)
# Everything it replaces is backed up to ~/.agent-config-backups/kiro-<timestamp>/. Safe to re-run.
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

SRC="$HERE/home/.kiro"
DEST="${KIRO_HOME:-$HOME/.kiro}"
[[ -f "$SRC/steering/AGENTS.md" ]] || die "source config not found at $SRC (run: make build)"
need kiro-cli "Kiro CLI is not installed - config is still staged, install the CLI to use it"
need python3 "required by the guardrails hook (it runs the shared guard)"
need op      "1Password CLI - the wrapper reads the gateway key at launch"

log "kiro config -> $DEST ($(os_kind))"
CONFIG_FILES=(steering/AGENTS.md kiro-env.sh hooks/kiro_guard.py permissions.yaml)
for rel in "${CONFIG_FILES[@]}"; do install_file kiro "$SRC/$rel" "$DEST/$rel"; done
for d in agents prompts skills plugins; do
  [[ -d "$SRC/$d" ]] || continue
  run mkdir -p "$DEST/$d"
  while IFS= read -r -d '' f; do
    [[ "$(basename "$f")" == .gitkeep ]] && continue
    install_file kiro "$f" "$DEST/${f#"$SRC"/}"
  done < <(find "$SRC/$d" -type f -print0)
done
merge_config kiro "$SRC/settings/cli.json" "$DEST/settings/cli.json"

install_guard kiro "$DEST/hooks"

ensure_shell_source kiro "$DEST/kiro-env.sh"

if [[ "$DRY_RUN" != 1 ]]; then
  python3 "$DEST/hooks/guard.py" --self-test >/dev/null && log "guard self-test passed" || die "guard self-test failed"
fi

log "kiro install complete. Smoke test: open a new shell, run kiro-cli with a one-shot prompt via the gateway model."
