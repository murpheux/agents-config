#!/usr/bin/env bash
# Install the Pi (pi.dev) agent configuration into ${PI_CODING_AGENT_DIR:-~/.pi/agent} (macOS or Linux/WSL).
# Everything it replaces is backed up to ~/.agent-config-backups/pi-<timestamp>/.
#   ./install.sh              install
#   ./install.sh --prune      also move skills/prompts/extensions that are NOT part of this config into the backup
#   DRY_RUN=1 ./install.sh    preview
set -Eeuo pipefail
HERE="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
source "$HERE/lib/install-lib.sh"
PRUNE=0; [[ "${1:-}" == "--prune" ]] && PRUNE=1

SRC="$HERE/home/.pi/agent"
DEST="${PI_CODING_AGENT_DIR:-$HOME/.pi/agent}"
[[ -f "$SRC/AGENTS.md" ]] || die "source config not found at $SRC"

# Never copied: Pi's own runtime/credential state (never seed or overwrite these from a config repo).
skip() {
  case "$1" in
    auth.json|mcp-auth.json|mcp.log|mcp.log.1|.DS_Store|*/.DS_Store|trust.json) return 0 ;;
  esac
  return 1
}

log "Pi agent config → $DEST ($(os_kind))"
while IFS= read -r -d '' f; do
  rel="${f#"$SRC"/}"
  skip "$rel" && continue
  install_file pi "$f" "$DEST/$rel"
done < <(find "$SRC" -type f -print0)

# Stale skills/prompts/extensions from an older config would still be loaded by Pi.
for d in skills prompts extensions; do
  [[ -d "$DEST/$d" ]] || continue
  while IFS= read -r -d '' entry; do
    name="${entry#"$DEST/$d/"}"
    [[ -e "$SRC/$d/$name" ]] && continue
    if [[ "$PRUNE" == 1 ]]; then
      backup_path pi "$entry"; run rm -rf -- "$entry"; log "pruned stale $d/$name"
    else
      warn "stale $d/$name is not part of this config (re-run with --prune to move it into the backup)"
    fi
  done < <(find "$DEST/$d" -mindepth 1 -maxdepth 1 -print0)
done

if [[ "$DRY_RUN" != 1 ]]; then
  for j in settings.json mcp.json models.json; do
    [[ -f "$DEST/$j" ]] || continue
    python3 -c "import json,sys; json.load(open(sys.argv[1]))" "$DEST/$j" \
      && log "$j parses" || die "installed $j does not parse"
  done
fi

need pi      "install Pi: npm install -g @mariozechner/pi-coding-agent (or see https://pi.dev/docs/latest/installation)"
need python3 "used to validate the installed JSON config"
need op      "1Password CLI (credentials are injected, never stored)"
need uv      "needed by the awsdocs MCP server (uvx) — remove it from mcp.json if unused"
need docker  "needed by the terraform MCP server — remove it from mcp.json if unused"

cat <<'EOF'

Next steps
  1. Provider/MCP env (via 1Password or your shell profile — never in this repo):
       AGENTGATEWAY_API_KEY   OPENROUTER_API_KEY   GITHUB_PAT   CONTEXT7_API_KEY
  2. Trust the gateway's private TLS cert (Pi runs on Node, which ignores the macOS keychain):
       export NODE_EXTRA_CA_CERTS=/Users/Shared/nfs_share/docker_volumes/agentgw/tls/cert.pem
     Without it, every agentgateway request fails with "Connection error." Never use
     NODE_TLS_REJECT_UNAUTHORIZED=0 instead.
  3. Verify:
       pi --list-models
       pi mcp list
  4. First run in any project: Pi will ask to trust it before loading that project's own .pi/ config
     (settings.json, mcp.json, extensions, skills, prompts) — see defaultProjectTrust in settings.json.
  5. Untrusted/autonomous work: run Pi inside a container or VM (see security.md#containerization in
     the Pi docs) — there is no in-app sandbox equivalent to fall back on.
EOF
