#!/usr/bin/env bash
# Install the OpenCode v2 configuration into ${XDG_CONFIG_HOME:-~/.config}/opencode (macOS or Linux/WSL).
# Everything it replaces is backed up to ~/.agent-config-backups/opencode-<timestamp>/.
#   ./install.sh              install
#   ./install.sh --prune      also move agents/commands/skills that are NOT part of this config into the backup
#   DRY_RUN=1 ./install.sh    preview
set -Eeuo pipefail
HERE="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
source "$HERE/lib/install-lib.sh"
PRUNE=0; [[ "${1:-}" == "--prune" ]] && PRUNE=1

SRC="$HERE/.config/opencode"
DEST="${XDG_CONFIG_HOME:-$HOME/.config}/opencode"
[[ -f "$SRC/opencode.jsonc" ]] || die "source config not found at $SRC"

# Never copied: machine-specific service registration (contains the service password), OS junk, and files
# OpenCode manages itself. cli.json (terminal prefs) is only installed when you don't have one yet.
skip() {
  case "$1" in
    service.json|.DS_Store|*/.DS_Store|package.json|package-lock.json|bun.lock|node_modules/*|.git/*|cli.json) return 0 ;;
  esac
  return 1
}

log "OpenCode config → $DEST ($(os_kind))"
while IFS= read -r -d '' f; do
  rel="${f#"$SRC"/}"
  skip "$rel" && continue
  install_file opencode "$f" "$DEST/$rel"
done < <(find "$SRC" -type f -print0)
if [[ -f "$SRC/cli.json" && ! -f "$DEST/cli.json" ]]; then install_file opencode "$SRC/cli.json" "$DEST/cli.json"; fi

# Stale agents/commands/skills from an older config would still be loaded by OpenCode.
for d in agents commands skills; do
  [[ -d "$DEST/$d" ]] || continue
  for entry in "$DEST/$d"/*; do
    [[ -e "$entry" ]] || continue
    name="$(basename "$entry")"
    [[ -e "$SRC/$d/$name" ]] && continue
    if [[ "$PRUNE" == 1 ]]; then
      backup_path opencode "$entry"; run rm -rf -- "$entry"; log "pruned stale $d/$name"
    else
      warn "stale $d/$name is not part of this config (re-run with --prune to move it into the backup)"
    fi
  done
done

if [[ "$DRY_RUN" != 1 ]]; then
  python3 - "$DEST/opencode.jsonc" <<'PY' && log "opencode.jsonc parses" || die "installed opencode.jsonc does not parse"
import json, re, sys
s = open(sys.argv[1], encoding="utf-8").read()
out, i, n, q = [], 0, len(s), False
while i < n:
    c = s[i]
    if q:
        out.append(c)
        if c == "\\": out.append(s[i + 1]); i += 2; continue
        if c == '"': q = False
        i += 1; continue
    if c == '"': q = True; out.append(c); i += 1; continue
    if s.startswith("//", i):
        while i < n and s[i] != "\n": i += 1
        continue
    out.append(c); i += 1
json.loads(re.sub(r",(\s*[}\]])", r"\1", "".join(out)))
PY
fi

need opencode "install OpenCode v2: https://opencode.ai/v2/docs/cli"
need python3  "used to validate the installed config"
need op       "1Password CLI (credentials are injected, never stored)"

cat <<'EOF'

Next steps
  1. Provider/MCP env (via 1Password or your shell profile — never in the config):
       AGENTGATEWAY_API_KEY  GITHUB_PAT  CONTEXT7_API_KEY
     and make them visible to the background service:
       opencode service set env AGENTGATEWAY_API_KEY "$AGENTGATEWAY_API_KEY"
  2. Trust the gateway CA instead of disabling TLS checks:
       opencode service set env NODE_EXTRA_CA_CERTS /path/to/homelab-ca.pem
       opencode service unset env NODE_TLS_REJECT_UNAUTHORIZED
       opencode service restart
  3. In OpenCode: /connect → OpenRouter (planner/architect/security), then check  opencode mcp list
EOF
