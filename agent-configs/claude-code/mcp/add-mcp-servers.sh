#!/usr/bin/env bash
# Register user-scope MCP servers for Claude Code (stored in ~/.claude.json — never edit that file by hand).
# Secrets are referenced as ${VAR} literals and expanded by Claude Code at runtime, so no token is written to disk.
set -Eeuo pipefail
command -v claude >/dev/null || { echo "claude CLI not found" >&2; exit 1; }

add() { local name="$1" json="$2"; claude mcp remove --scope user "$name" >/dev/null 2>&1 || true; claude mcp add-json --scope user "$name" "$json"; echo "added $name"; }

# GitHub (remote, read-only, 5 toolsets). Needs GITHUB_PAT in the environment Claude starts from.
add github '{"type":"http","url":"https://api.githubcopilot.com/mcp/","headers":{"Authorization":"Bearer ${GITHUB_PAT}","X-MCP-Toolsets":"repos,issues,pull_requests,actions,code_security","X-MCP-Readonly":"true"}}'
# Library docs
add context7 '{"type":"http","url":"https://mcp.context7.com/mcp","headers":{"CONTEXT7_API_KEY":"${CONTEXT7_API_KEY}"}}'
# Microsoft Learn (C#/.NET, Azure, PowerShell) — free, no auth
add mslearn '{"type":"http","url":"https://learn.microsoft.com/api/mcp"}'
# AWS documentation (no AWS credentials involved) — needs uv
add awsdocs '{"type":"stdio","command":"uvx","args":["awslabs.aws-documentation-mcp-server@latest"],"env":{"FASTMCP_LOG_LEVEL":"ERROR","AWS_DOCUMENTATION_PARTITION":"aws"}}'
# Terraform registry — needs Docker
add terraform '{"type":"stdio","command":"docker","args":["run","-i","--rm","hashicorp/terraform-mcp-server"]}'

cat <<'EOF'
Optional plugins (run inside Claude Code):
  /plugin marketplace add jgraph/drawio-mcp     then  /plugin install drawio@drawio      (official draw.io)
  /plugin install security-guidance@claude-code-plugins                                   (Anthropic security hooks)
EOF
claude mcp list
