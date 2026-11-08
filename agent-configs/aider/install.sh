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

need aider   "install with: uv tool install --force --python python3.12 --with pip aider-chat@latest"
need op      "1Password CLI is required by the ai* aliases"
need ggshield "pre-commit secret scanning (git-commit-verify: true runs hooks)"

cat <<'EOF'

Next steps
  1. Add to ~/.zshrc (or ~/.bashrc):   source ~/.aider/aider-aliases.sh
  2. Edit ~/.aider/aider.op.env so the op:// references match your 1Password vault.
  3. Per repo: copy templates/.aiderignore to the repo root, and install the ggshield hook:
       ggshield install --mode local        # or add ggshield to .pre-commit-config.yaml
  4. Add Aider artefacts to your global gitignore:
       git config --global core.excludesFile ~/.gitignore_global && echo '.aider*' >> ~/.gitignore_global
  5. Replace the placeholder prices in ~/.aider/model.metadata.json with your gateway rates.
EOF
