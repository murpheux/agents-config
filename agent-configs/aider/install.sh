#!/usr/bin/env bash
# Install the Aider configuration into $HOME (macOS or Linux/WSL). Backs up anything it replaces.
#   ./install.sh            install
#   DRY_RUN=1 ./install.sh  show what would happen
set -Eeuo pipefail
HERE="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
source "$HERE/lib/install-lib.sh"

log "Aider config → $HOME ($(os_kind), CA bundle $(ca_bundle))"
install_file aider "$HERE/home/.aider.conf.yml" "$HOME/.aider.conf.yml"
install_tree aider "$HERE/home/.aider" "$HOME/.aider"
run chmod +x "$HOME/.aider/bin/lint-go"
run chmod 600 "$HOME/.aider/aider.op.env"

# Aider's Python/OpenSSL trusts only SSL_CERT_FILE (never the macOS keychain): export the OS trust
# store, home-lab CA included, and verify it against the gateway.
if [[ "$DRY_RUN" == 1 ]]; then echo "DRY: node lib/build-ca-bundle.mjs $HOME/.aider/ca-bundle.pem"
elif command -v node >/dev/null; then
  node "$HERE/lib/build-ca-bundle.mjs" "$HOME/.aider/ca-bundle.pem" || die "CA bundle does not verify scarlet:9443 — is the home-lab CA trusted in the keychain?"
else
  die "node >= 22.15 is required to export the OS trust store (Aider's SSL_CERT_FILE points at ~/.aider/ca-bundle.pem)"
fi

need aider  "install with: uv tool install --force --python python3.12 --with pip aider-chat@latest"
need op      "1Password CLI is required by the ai* aliases"
need ggshield "pre-commit secret scanning (git-commit-verify: true runs hooks)"

cat <<'EOF'

Next steps
  1. Add to ~/.zshrc (or ~/.bashrc):   source ~/.aider/aider-aliases.sh
  2. Credentials: ~/.aider/aider.op.env uses op://private/agent-gateway-api-key/password (the same item
     as AGENTGATEWAY_API_KEY in ~/.zshrc). Every model, arch/sec included, goes through Agentgateway.
     Smoke test:  ai-ask --message "Reply with: ok" --no-git
  3. Per repo: copy templates/.aiderignore to the repo root, and install the ggshield hook:
       ggshield install --mode local        # or add ggshield to .pre-commit-config.yaml
  4. Add Aider artefacts to your global gitignore:
       git config --global core.excludesFile ~/.gitignore_global && echo '.aider*' >> ~/.gitignore_global
  5. Replace the placeholder prices in ~/.aider/model.metadata.json with your gateway rates.
EOF
