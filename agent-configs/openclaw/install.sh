#!/bin/bash
# OpenClaw agent configuration installer.
# Backs up existing config and installs fresh agent config for OpenClaw.
# Usage: DRY_RUN=1 ./install.sh    # preview only
#        ./install.sh               # install (creates backup)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HOME_DIR="${SCRIPT_DIR}/home"
INSTALL_LIB="${SCRIPT_DIR}/../_shared/install-lib.sh"

# Load shared installer library
if [[ ! -f "$INSTALL_LIB" ]]; then
    echo "ERROR: install-lib.sh not found at $INSTALL_LIB"
    exit 1
fi
# shellcheck disable=SC1090
source "$INSTALL_LIB"

# Configuration
TOOL_NAME="openclaw"
TOOL_HOME="${HOME}/.openclaw"
BACKUP_DIR="${HOME}/.agent-config-backups/${TOOL_NAME}"
INSTALL_FILES=(
    ".openclaw/openclaw.json"
    ".openclaw/workspace/CONVENTIONS.md"
    ".openclaw/workspace/USER.md"
    ".openclaw/workspace/MEMORY.md"
)

echo "═══════════════════════════════════════════════════════════════"
echo "OpenClaw Agent Configuration Installer"
echo "═══════════════════════════════════════════════════════════════"
echo ""
echo "Tool:        $TOOL_NAME"
echo "Home:        $TOOL_HOME"
echo "Backup:      $BACKUP_DIR"
echo "Install lib: $INSTALL_LIB"
echo ""

# Step 1: Create OpenClaw home directory if needed
if [[ ! -d "$TOOL_HOME" ]]; then
    install_log "Creating $TOOL_HOME"
    mkdir -p "$TOOL_HOME" || {
        install_error "Failed to create $TOOL_HOME"
        exit 1
    }
fi

# Step 2: Backup existing config (if DRY_RUN not set)
if [[ -f "$TOOL_HOME/openclaw.json" ]] && [[ "${DRY_RUN:-0}" != "1" ]]; then
    install_backup "$TOOL_HOME/openclaw.json" "$BACKUP_DIR" || exit 1
fi

# Step 3: Install config files
for rel_path in "${INSTALL_FILES[@]}"; do
    src="${HOME_DIR}/${rel_path}"
    dst="${HOME}/${rel_path}"

    if [[ ! -f "$src" ]]; then
        install_error "Source file not found: $src"
        exit 1
    fi

    install_log "Installing: $rel_path"
    if [[ "${DRY_RUN:-0}" == "1" ]]; then
        echo "  [DRY_RUN] Would copy: $src → $dst"
    else
        mkdir -p "$(dirname "$dst")"
        cp "$src" "$dst"
        chmod 600 "$dst"  # config.json should not be world-readable
        echo "  ✓ Installed to $dst"
    fi
done

# Step 4: Create workspace directory
WORKSPACE="${HOME}/.openclaw/workspace"
if [[ ! -d "$WORKSPACE" ]]; then
    install_log "Creating workspace directory: $WORKSPACE"
    if [[ "${DRY_RUN:-0}" == "1" ]]; then
        echo "  [DRY_RUN] Would create: $WORKSPACE"
    else
        mkdir -p "$WORKSPACE"
        chmod 700 "$WORKSPACE"
        echo "  ✓ Workspace directory created"
    fi
fi

# Step 5: Create agents directory
AGENTS_DIR="${HOME}/.openclaw/agents"
if [[ ! -d "$AGENTS_DIR" ]]; then
    install_log "Creating agents directory: $AGENTS_DIR"
    if [[ "${DRY_RUN:-0}" == "1" ]]; then
        echo "  [DRY_RUN] Would create: $AGENTS_DIR"
    else
        mkdir -p "$AGENTS_DIR/main/agent"
        chmod 700 "$AGENTS_DIR"
        echo "  ✓ Agents directory created"
    fi
fi

# Step 6: Create skills directory
SKILLS_DIR="${HOME}/.openclaw/skills"
if [[ ! -d "$SKILLS_DIR" ]]; then
    install_log "Creating skills directory: $SKILLS_DIR"
    if [[ "${DRY_RUN:-0}" == "1" ]]; then
        echo "  [DRY_RUN] Would create: $SKILLS_DIR"
    else
        mkdir -p "$SKILLS_DIR"
        chmod 700 "$SKILLS_DIR"
        echo "  ✓ Skills directory created"
    fi
fi

# Step 7: Summary
echo ""
echo "═══════════════════════════════════════════════════════════════"
if [[ "${DRY_RUN:-0}" == "1" ]]; then
    echo "✓ DRY RUN COMPLETE (no changes made)"
    echo ""
    echo "Next steps:"
    echo "  1. Review the changes above"
    echo "  2. Run without DRY_RUN=1 to install: ./install.sh"
else
    echo "✓ Installation complete!"
    echo ""
    echo "Installed files:"
    echo "  Root (~/.openclaw/):"
    echo "    ✓ openclaw.json              Configuration"
    echo ""
    echo "  Workspace (~/.openclaw/workspace/):"
    echo "    ✓ CONVENTIONS.md             Agent conventions & architecture"
    echo "    ✓ USER.md                    User profile & environment"
    echo "    ✓ MEMORY.md                  Setup context & troubleshooting"
    echo ""
    echo "  Agent definitions:"
    echo "    ✓ ~/.openclaw/agents/main/agent/system.md"
    echo ""
    echo "Next steps:"
    echo "  1. Review documentation:"
    echo "     cat ~/.openclaw/workspace/USER.md"
    echo "     cat ~/.openclaw/workspace/MEMORY.md"
    echo "  2. Store AGENTGATEWAY_API_KEY in credential manager:"
    echo "     op secret set AGENTGATEWAY_API_KEY=<token>"
    echo "  3. Verify gateway connectivity:"
    echo "     curl -k https://10.10.2.80:9443/v1/models"
    echo "  4. Restart OpenClaw service:"
    echo "     systemctl --user restart openclaw-gateway"
    echo "  5. Validate configuration:"
    echo "     openclaw config validate"
fi
echo ""
echo "Documentation: ~/.openclaw/CONVENTIONS.md"
echo "═══════════════════════════════════════════════════════════════"
