#!/usr/bin/env bash
# Install the Tau (huggingface/tau) configuration into ${TAU_HOME:-~/.tau} (macOS or Linux/WSL).
# Copies ONLY the config files below — never Tau's runtime state (sessions, logs, caches, credentials).
# Everything it replaces is backed up to ~/.agent-config-backups/tau-<timestamp>/.
#   ./install.sh              install            DRY_RUN=1 ./install.sh   preview
set -Eeuo pipefail
HERE="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
source "$HERE/lib/install-lib.sh"

SRC="$HERE/home/.tau"
DEST="${TAU_HOME:-$HOME/.tau}"
[[ -f "$SRC/AGENTS.md" ]] || die "source config not found at $SRC (run: make build)"

log "Tau config → $DEST ($(os_kind))"
CONFIG_FILES=(AGENTS.md catalog.toml tau-env.sh extensions/guardrails.py guard/guard.py guard/guardrails.json)
for rel in "${CONFIG_FILES[@]}"; do install_file tau "$SRC/$rel" "$DEST/$rel"; done
while IFS= read -r -d '' f; do install_file tau "$f" "$DEST/${f#"$SRC"/}"; done \
  < <(find "$SRC/prompts" "$SRC/skills" -type f -name '*.md' -print0)

# providers.json is Tau-owned runtime state: merge our keys (default provider/model), keep yours.
backup_path tau "$DEST/providers.json"
if [[ "$DRY_RUN" == 1 ]]; then echo "DRY: merge providers.fragment.json → $DEST/providers.json"
else python3 "$HERE/lib/merge_json.py" "$DEST/providers.json" "$SRC/providers.fragment.json" >/dev/null && log "providers.json merged (default provider: agentgateway)"; fi

# Tau reads credentials.json BEFORE api_key_env: drop the plaintext gateway key so 1Password wins.
backup_path tau "$DEST/credentials.json"
scrub_args=("$DEST"); [[ "$DRY_RUN" == 1 ]] && scrub_args+=(--dry-run)
python3 "$HERE/lib/scrub-credentials.py" "${scrub_args[@]}"

# TLS: httpx trusts only SSL_CERT_FILE — export the OS trust store (public roots + home-lab CA).
if [[ "$DRY_RUN" == 1 ]]; then echo "DRY: node lib/build-ca-bundle.mjs $DEST/ca-bundle.pem"
elif command -v node >/dev/null; then
  node "$HERE/lib/build-ca-bundle.mjs" "$DEST/ca-bundle.pem" || die "CA bundle does not verify scarlet:9443 — is the gateway cert trusted in the keychain?"
else
  die "node >= 22.15 is required to export the OS trust store (tau-env.sh uses $DEST/ca-bundle.pem)"
fi

if [[ "$DRY_RUN" != 1 ]]; then
  python3 "$DEST/guard/guard.py" --self-test >/dev/null && log "guard self-test passed" || die "guard self-test failed"
fi

# Heads-ups (never auto-changed: they are yours / third-party code).
[[ -e "$HOME/.agents/AGENTS.md" ]] && warn "Tau ALSO loads ~/.agents/AGENTS.md ($(readlink "$HOME/.agents/AGENTS.md" 2>/dev/null || echo file)) — the global instructions would load twice; remove or retarget it if it isn't meant for Tau."
[[ -d "$HOME/.agents/skills" ]] || warn "$HOME/.agents/skills missing — topic skills (golang, terraform, …) come from the Codex config: (cd ../codex && ./install.sh)"
[[ -d "$DEST/extensions/tau-herdr" ]] || log "optional: herdr orchestration extension (third-party code — review first):  tau install git:github.com/rian-dolphin/tau-herdr"

need tau     "install: uv tool install tau-ai"
need node    "exports the OS trust store into $DEST/ca-bundle.pem"
need op      "1Password CLI — the tau wrapper reads the gateway key at launch"
need python3 "required by the guardrails extension's shared guard"

cat <<'EOF'

Next steps
  1. Add to ~/.zshrc (after the SSL_CERT_FILE block):   source ~/.tau/tau-env.sh      then: exec zsh
     `tau` then runs with the gateway key from 1Password and ~/.tau/ca-bundle.pem as its only CA bundle.
  2. Smoke test:   tau --provider agentgateway --model deepseek-flash --print "Reply with: ok"
  3. Inside Tau:   /model (gateway models), /skills (role-* + ~/.agents/skills), /reload after edits.
EOF
