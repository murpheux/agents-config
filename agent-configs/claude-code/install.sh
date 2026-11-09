#!/usr/bin/env bash
# Install the Claude Code configuration (macOS or Linux/WSL2). Backs up what it replaces.
# Claude Code reads its user config from $CLAUDE_CONFIG_DIR, or ~/.claude when that is unset.
#   ./install.sh                    install into $CLAUDE_CONFIG_DIR (or ~/.claude if unset)
#   ./install.sh --target DIR       install into DIR (repeatable: --target ~/.claude --target ~/.config/claude)
#   ./install.sh --both             install into both ~/.claude and ~/.config/claude
#   ./install.sh --gateway          also route through Agentgateway (merges settings.gateway.json); combinable
#   DRY_RUN=1 ./install.sh …        preview
set -Eeuo pipefail
HERE="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
source "$HERE/lib/install-lib.sh"

usage() { sed -n '2,8p' "$0" | sed 's/^# \{0,1\}//'; exit "${1:-0}"; }
GATEWAY=0; TARGETS=()
while [[ $# -gt 0 ]]; do
  case "$1" in
    --gateway) GATEWAY=1 ;;
    --both)    TARGETS+=("$HOME/.claude" "$HOME/.config/claude") ;;
    --target)  [[ -n "${2:-}" ]] || die "--target needs a directory"; TARGETS+=("$2"); shift ;;
    --target=*) TARGETS+=("${1#--target=}") ;;
    -h|--help) usage 0 ;;
    *) warn "unknown option: $1"; usage 1 ;;
  esac
  shift
done
[[ ${#TARGETS[@]} -gt 0 ]] || TARGETS=("${CLAUDE_CONFIG_DIR:-$HOME/.claude}")

# Normalise (expand ~, make absolute, drop duplicates).
declare -a DESTS=()
for t in "${TARGETS[@]}"; do
  t="${t/#\~/$HOME}"; [[ "$t" = /* ]] || t="$PWD/$t"; t="${t%/}"
  [[ " ${DESTS[*]-} " == *" $t "* ]] || DESTS+=("$t")
done

# Files ship with ~/.claude paths (hook/status-line commands, deny rules, docs). For any other config dir,
# rewrite only HOME-anchored forms — project-relative ".claude/" paths are left alone.
retarget() {
  local dest="$1"
  [[ "$dest" == "$HOME/.claude" || "$DRY_RUN" == 1 ]] && { [[ "$DRY_RUN" == 1 && "$dest" != "$HOME/.claude" ]] && echo "DRY: retarget ~/.claude paths → $dest"; return 0; }
  python3 - "$dest" "$HOME" "$HERE/home/.claude" <<'PY'
import pathlib, sys
dest, home, src = pathlib.Path(sys.argv[1]), sys.argv[2], pathlib.Path(sys.argv[3])
tilde = "~" + str(dest)[len(home):] if str(dest).startswith(home + "/") else str(dest)
subs = [(f"{home}/.claude/", f"{dest}/"), ("$HOME/.claude/", f"{dest}/"), ("${HOME}/.claude/", f"{dest}/"), ("~/.claude/", f"{tilde}/")]
total = 0
# Only files this installer just copied — never the user's own data in the config dir (memories, projects, todos).
for rel in sorted(q.relative_to(src) for q in src.rglob("*") if q.is_file()):
    p = dest / rel
    if p.suffix not in {".json", ".md", ".py", ".sh"} or p.name == "guardrails.json" or not p.is_file():
        continue
    text = p.read_text(encoding="utf-8", errors="strict")
    new, n = text, 0
    for a, b in subs:
        n += new.count(a); new = new.replace(a, b)
    if n:
        p.write_text(new, encoding="utf-8"); total += n
        print(f"    retargeted {n:>2} path(s) in {p.relative_to(dest)}")
left = [n for n in ("settings.json", "settings.gateway.json") if (dest / n).is_file() and any(a in (dest / n).read_text() for a, _ in subs)]
if left: print("    WARNING: ~/.claude paths remain in", ", ".join(left))
print(f"    {total} ~/.claude path(s) → {dest}")
PY
}

for DEST in "${DESTS[@]}"; do
  log "Claude Code config → $DEST ($(os_kind))"
  install_tree claude-code "$HERE/home/.claude" "$DEST"
  retarget "$DEST"
  run chmod +x "$DEST/hooks/guard.py" "$DEST/statusline.py"

  if [[ "$DRY_RUN" != 1 ]]; then
    python3 "$DEST/hooks/guard.py" --self-test >/dev/null && log "guard hook self-test passed ($DEST)" \
      || die "guard hook self-test failed — the PreToolUse gate would fail open"
    if [[ "$GATEWAY" == 1 ]]; then
      python3 - "$DEST/settings.json" "$DEST/settings.gateway.json" <<'PY'
import json, sys
base, overlay = (json.load(open(p)) for p in sys.argv[1:3])
for k, v in overlay.items():
    if k.startswith("_"):
        continue
    if isinstance(v, dict) and isinstance(base.get(k), dict):
        base[k].update(v)
    else:
        base[k] = v
json.dump(base, open(sys.argv[1], "w"), indent=2)
print("merged gateway overlay into", sys.argv[1])
PY
    fi
  fi
done

ACTIVE="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"
[[ " ${DESTS[*]} " == *" $ACTIVE "* ]] || warn "Claude Code currently reads $ACTIVE (CLAUDE_CONFIG_DIR=${CLAUDE_CONFIG_DIR:-unset}), which this run did not install to."

need claude  "install: curl -fsSL https://claude.ai/install.sh | bash   (review the script first)"
need python3 "required by the guard hook and status line"
[[ "$(os_kind)" == wsl ]] && { need bwrap "sandbox on WSL2 needs: sudo apt install bubblewrap socat"; need socat "sandbox on WSL2"; }

cat <<EOF

Next steps (installed to: ${DESTS[*]})
  1. Register MCP servers (user scope) — once per config dir, since each keeps its own .claude.json:
       CLAUDE_CONFIG_DIR=<dir> ./mcp/add-mcp-servers.sh      (omit CLAUDE_CONFIG_DIR for ~/.claude)
  2. Start:                               claude            (main session = router on Haiku)
     Direct session without the router:   ROUTER_MODE=off claude --agent developer
  3. Check the setup:                     /agents   /hooks   /permissions   /context
  4. Cost reports (optional):             npx ccusage@latest
EOF
