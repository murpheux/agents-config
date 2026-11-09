#!/usr/bin/env bash
# Install the oh-my-pi (omp) configuration into ${PI_CODING_AGENT_DIR:-~/.omp/agent} (macOS or Linux/WSL).
# Copies ONLY the config files below — never omp's runtime state (*.db, sessions, natives, caches).
# config.yml is updated through `omp config set` (omp's own writer: your keys are kept, enums validated).
# Everything it replaces is backed up to ~/.agent-config-backups/omp-<timestamp>/.
#   ./install.sh              install            DRY_RUN=1 ./install.sh   preview
set -Eeuo pipefail
HERE="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
source "$HERE/lib/install-lib.sh"

SRC="$HERE/home/.omp/agent"
DEST="${PI_CODING_AGENT_DIR:-$HOME/.omp/agent}"
[[ -f "$SRC/AGENTS.md" ]] || die "source config not found at $SRC (run: make build)"
command -v omp >/dev/null || die "omp not found — install it first (brew install omp)"

log "omp config → $DEST ($(os_kind))"
CONFIG_FILES=(AGENTS.md models.yml omp-env.sh extensions/guardrails.ts guard/guard.py guard/guardrails.json guard/omp_guard.py)
[[ -f "$DEST/models.yml" ]] && warn "replacing your models.yml (backed up) — re-add any custom providers from the backup"
for rel in "${CONFIG_FILES[@]}"; do install_file omp "$SRC/$rel" "$DEST/$rel"; done
while IFS= read -r -d '' f; do install_file omp "$f" "$DEST/${f#"$SRC"/}"; done \
  < <(find "$SRC/agents" "$SRC/prompts" -type f -name '*.md' -print0)

# Settings: one `omp config set` per key from config.settings.json (values passed as JSON).
backup_path omp "$DEST/config.yml"
while IFS=$'\t' read -r key value; do
  if [[ "$DRY_RUN" == 1 ]]; then echo "DRY: omp config set $key $value"; continue; fi
  PI_CODING_AGENT_DIR="$DEST" command omp config set "$key" "$value" >/dev/null || die "omp config set $key failed"
done < <(python3 -c 'import json,sys
for k, v in json.load(open(sys.argv[1])).items():
    if not k.startswith("_"): print(f"{k}\t{json.dumps(v) if not isinstance(v, str) else v}")' "$SRC/config.settings.json")
[[ "$DRY_RUN" == 1 ]] || log "config.yml updated (model roles → Agentgateway, approval mode: write)"

# TLS: omp (Bun) honours NODE_EXTRA_CA_CERTS — export the OS trust store (public roots + home-lab CA).
if [[ "$DRY_RUN" == 1 ]]; then echo "DRY: node lib/build-ca-bundle.mjs $DEST/ca-bundle.pem"
elif command -v node >/dev/null; then
  node "$HERE/lib/build-ca-bundle.mjs" "$DEST/ca-bundle.pem" || die "CA bundle does not verify scarlet:9443 — is the gateway cert trusted in the keychain?"
else
  die "node >= 22.15 is required to export the OS trust store (omp-env.sh uses $DEST/ca-bundle.pem)"
fi

if [[ "$DRY_RUN" != 1 ]]; then
  python3 "$DEST/guard/guard.py" --self-test >/dev/null && log "guard self-test passed" || die "guard self-test failed"
fi

need python3 "required by the guardrails extension (it runs the shared guard)"
need node    "exports the OS trust store into $DEST/ca-bundle.pem"
need op      "1Password CLI — the omp wrapper reads the gateway key at launch"
[[ -d "$HOME/.agents/skills" ]] || warn "$HOME/.agents/skills missing — topic skills come from the Codex config: (cd ../codex && ./install.sh)"

cat <<'EOF'

Next steps
  1. Add to ~/.zshrc (after the SSL_CERT_FILE block):   source ~/.omp/agent/omp-env.sh      then: exec zsh
  2. Smoke test:    omp -p --model agentgateway/deepseek-flash "Reply with: ok"
  3. In omp:        /model (gateway models), /extensions (guardrails loaded), ask it to "use the explorer agent".
EOF
