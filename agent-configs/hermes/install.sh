#!/usr/bin/env bash
# Install the Hermes Agent (NousResearch/hermes-agent) configuration into ${HERMES_HOME:-~/.hermes}.
# Copies ONLY the config files below — never Hermes' runtime state (state.db, sessions, memories, .env…).
# Everything it changes is backed up to ~/.agent-config-backups/hermes-<timestamp>/.
#   ./install.sh              install            DRY_RUN=1 ./install.sh   preview
set -Eeuo pipefail
HERE="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
source "$HERE/lib/install-lib.sh"

SRC="$HERE/home/.hermes"
DEST="${HERMES_HOME:-$HOME/.hermes}"
HERMES_PY="${HERMES_PY:-$DEST/hermes-agent/venv/bin/python3}"   # Hermes' own interpreter (has PyYAML)
[[ -f "$SRC/SOUL.md" ]] || die "source config not found at $SRC (run: make build)"
[[ -x "$HERMES_PY" ]] || die "Hermes interpreter not found at $HERMES_PY (set HERMES_PY=…)"
OP_BIN="$(command -v op || true)"
[[ -n "$OP_BIN" ]] || die "1Password CLI (op) not found — the gateway provider's key_cmd needs it"

log "Hermes config → $DEST ($(os_kind))"
CONFIG_FILES=(SOUL.md hermes-env.sh agent-hooks/guardrails-hook.py guard/guard.py guard/guardrails.json)
for rel in "${CONFIG_FILES[@]}"; do install_file hermes "$SRC/$rel" "$DEST/$rel"; done
run chmod +x "$DEST/agent-hooks/guardrails-hook.py"
while IFS= read -r -d '' f; do install_file hermes "$f" "$DEST/${f#"$SRC"/}"; done \
  < <(find "$SRC/skills" -type f -name 'SKILL.md' -print0)

# Hermes-owned files: merge, never overwrite (config.yaml, shell-hook consent, .env).
for f in config.yaml shell-hooks-allowlist.json .env; do backup_path hermes "$DEST/$f"; done
cfg_args=("$DEST" "$SRC/config.fragment.yaml" --op "$OP_BIN"); [[ "$DRY_RUN" == 1 ]] && cfg_args+=(--dry-run)
"$HERMES_PY" "$HERE/lib/configure-hermes.py" "${cfg_args[@]}"

# TLS: the provider's ssl_ca_cert points here — the OS trust store (public roots + home-lab CA).
if [[ "$DRY_RUN" == 1 ]]; then echo "DRY: node lib/build-ca-bundle.mjs $DEST/ca-bundle.pem"
elif command -v node >/dev/null; then
  node "$HERE/lib/build-ca-bundle.mjs" "$DEST/ca-bundle.pem" || die "CA bundle does not verify scarlet:9443 — is the gateway cert trusted in the keychain?"
else
  die "node >= 22.15 is required to export the OS trust store ($DEST/ca-bundle.pem)"
fi

if [[ "$DRY_RUN" != 1 ]]; then
  "$HERMES_PY" "$DEST/guard/guard.py" --self-test >/dev/null && log "guard self-test passed" || die "guard self-test failed"
  printf '%s' '{"hook_event_name":"pre_tool_call","tool_name":"terminal","tool_input":{"command":"rm -rf ~"}}' \
    | "$HERMES_PY" "$DEST/agent-hooks/guardrails-hook.py" | grep -q '"block"' && log "hook blocks rm -rf ~ ✔" || die "hook smoke test failed"
fi

[[ -d "$HOME/.agents/skills" ]] || warn "$HOME/.agents/skills missing — topic skills come from the Codex config: (cd ../codex && ./install.sh)"
need hermes  "install: https://github.com/NousResearch/hermes-agent"
need node    "exports the OS trust store into $DEST/ca-bundle.pem"

cat <<'EOF'

Next steps
  1. Add to ~/.zshrc:   source ~/.hermes/hermes-env.sh     (herdr/tmux panes: gateway bypasses inherited proxies)
  2. Check:            hermes hooks list      (guardrails: allowlisted)   ·   hermes hooks doctor
  3. Smoke test:       hermes chat -q "Reply with: ok"    (first gateway call may show a 1Password prompt)
  4. Inside Hermes:    /model custom:agentgateway:<model> · /role-<name> · /wf-<workflow> · /skills
EOF
