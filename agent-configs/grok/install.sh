#!/usr/bin/env bash
# Install the grok-cli (@vibe-kit/grok-cli) configuration into ~/.grok (macOS or Linux/WSL).
# Copies ONLY the config files below — never grok-cli's runtime state; leaves ~/.grok/hooks and
# ~/.grok/skills (third-party herdr/orca files) alone. Backups go to ~/.agent-config-backups/grok-<ts>/.
#   ./install.sh              install            DRY_RUN=1 ./install.sh   preview
set -Eeuo pipefail
HERE="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
source "$HERE/lib/install-lib.sh"

SRC="$HERE/home/.grok"
DEST="$HOME/.grok"     # grok-cli hard-codes ~/.grok (utils/settings-manager.js, custom-instructions.js)
[[ -f "$SRC/GROK.md" ]] || die "source config not found at $SRC (run: make build)"

log "grok-cli config → $DEST ($(os_kind))"
CONFIG_FILES=(GROK.md grok-env.sh grok-preload.cjs guard/guard.py guard/guardrails.json)
for rel in "${CONFIG_FILES[@]}"; do install_file grok "$SRC/$rel" "$DEST/$rel"; done

# user-settings.json is grok-cli-owned: gateway baseURL/defaultModel, models replaced, plaintext apiKey removed.
backup_path grok "$DEST/user-settings.json"
cfg_args=("$DEST" "$SRC/user-settings.fragment.json"); [[ "$DRY_RUN" == 1 ]] && cfg_args+=(--dry-run)
python3 "$HERE/lib/configure-settings.py" "${cfg_args[@]}"

# TLS: Node never reads the macOS keychain — export the OS trust store for NODE_EXTRA_CA_CERTS.
if [[ "$DRY_RUN" == 1 ]]; then echo "DRY: node lib/build-ca-bundle.mjs $DEST/ca-bundle.pem"
elif command -v node >/dev/null; then
  node "$HERE/lib/build-ca-bundle.mjs" "$DEST/ca-bundle.pem" || die "CA bundle does not verify scarlet:9443 — is the gateway cert trusted in the keychain?"
else
  die "node >= 22.15 is required to export the OS trust store (grok-env.sh uses $DEST/ca-bundle.pem)"
fi

if [[ "$DRY_RUN" != 1 ]]; then
  python3 "$DEST/guard/guard.py" --self-test >/dev/null && log "guard self-test passed" || die "guard self-test failed"
fi

# Heads-ups (never auto-changed).
[[ -f "$DEST/settings.json" ]] && warn "$DEST/settings.json is grok-cli's PROJECT file for \$HOME (pins a model when grok runs in ~); the wrapper's default model overrides non-gateway pins."
[[ -d "$DEST/hooks" || -d "$DEST/skills" ]] && log "note: $DEST/hooks and $DEST/skills (herdr/orca) are not read by grok-cli 1.0.1 — left untouched."

need grok    "install: npm i -g @vibe-kit/grok-cli"
need node    "runs grok-cli and exports the OS trust store"
need op      "1Password CLI — the grok wrapper reads the gateway key at launch"
need python3 "required by the guard preload's shared guard"

cat <<'EOF'

Next steps
  1. Add to ~/.zshrc:   source ~/.grok/grok-env.sh      then: exec zsh   (check: whence -w grok → function)
  2. Smoke test:        grok -m deepseek-flash -p "Reply with: ok"
  3. Per project:       .grok/GROK.md REPLACES ~/.grok/GROK.md; /models pins a model in .grok/settings.json.
EOF
