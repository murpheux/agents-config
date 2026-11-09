"""Offline checks for the Hermes config, run with Hermes' own interpreter so its real schema, provider
resolver, shell-hook parser, prompt scanner and command registry are used.

    make test        (= ~/.hermes/hermes-agent/venv/bin/python3 tests/test_config.py)
"""
from __future__ import annotations

import json
import os
import re
import subprocess
import sys
import tempfile
from pathlib import Path

sys.dont_write_bytecode = True
ROOT = Path(__file__).resolve().parent.parent
HOME = ROOT / "home" / ".hermes"
HOOK = HOME / "agent-hooks" / "guardrails-hook.py"
GATEWAY_MODELS = {"deepseek-flash", "claude-sonnet-5", "openrouter/openai/gpt-6-sol", "openrouter/anthropic/claude-opus-5-5"}
SECRETISH = re.compile(r"(?i)(sk-[A-Za-z0-9-]{12,}|\b[a-f0-9]{40,}\b|bearer\s+[A-Za-z0-9._-]{20,})")
HERMES_SRC = Path(os.environ.get("HERMES_SRC", Path.home() / ".hermes" / "hermes-agent"))
sys.path.insert(0, str(HERMES_SRC))


def _configured_home() -> Path:
    """A throwaway HERMES_HOME produced by the real configure step (with a pre-existing config to merge)."""
    home = Path(tempfile.mkdtemp(prefix="hermes-test-"))
    (home / "config.yaml").write_text(
        "model: {provider: copilot, default: x, base_url: http://stale}\n"
        "custom_providers: [{name: ollama, base_url: 'http://127.0.0.1:11434', api_mode: chat_completions}]\n"
        "skills: {external_dirs: [~/team-skills]}\n"
        "hooks: {pre_tool_call: [{command: '/old/agent-hooks/guardrails-hook.py'}, {command: /keep/me.sh}]}\n"
        "display: {skin: default}\n")
    (home / ".env").write_text("OTHER_KEY=keep\nAGENTGATEWAY_API_KEY=dummy-not-real\n")
    subprocess.run([sys.executable, str(ROOT / "lib" / "configure-hermes.py"), str(home),
                    str(HOME / "config.fragment.yaml"), "--op", "/opt/homebrew/bin/op"], check=True, capture_output=True)
    return home


def test_merge_keeps_user_keys_and_replaces_old_hook() -> None:
    import yaml

    home = _configured_home()
    cfg = yaml.safe_load((home / "config.yaml").read_text())
    assert cfg["display"]["skin"] == "default" and cfg["custom_providers"][0]["name"] == "ollama"
    assert cfg["model"] == {"provider": "custom:agentgateway", "default": "claude-sonnet-5", "base_url": ""}
    assert cfg["skills"]["external_dirs"] == ["~/team-skills", "~/.agents/skills"]
    cmds = [h["command"] for h in cfg["hooks"]["pre_tool_call"]]
    assert "/keep/me.sh" in cmds and "/old/agent-hooks/guardrails-hook.py" not in cmds
    hook = next(h for h in cfg["hooks"]["pre_tool_call"] if "guardrails-hook.py" in h["command"])
    assert hook["fail_closed"] is True and str(home) in hook["command"]
    allow = json.loads((home / "shell-hooks-allowlist.json").read_text())["approvals"]
    assert {"event": "pre_tool_call", "command": hook["command"]} in allow, "consent must match the exact command"
    env = (home / ".env").read_text()
    assert "AGENTGATEWAY_API_KEY" not in env and "OTHER_KEY=keep" in env
    assert cfg["context_file_max_chars"] >= len((HOME / "SOUL.md").read_text()), "SOUL.md would be truncated"


def test_provider_entry_passes_hermes_schema_and_resolves() -> None:
    import yaml

    home = _configured_home()
    entry = yaml.safe_load((home / "config.yaml").read_text())["providers"]["agentgateway"]
    from hermes_cli import config_providers as cp

    assert set(entry) <= cp._KNOWN_PROVIDER_KEYS, f"unknown keys: {set(entry) - cp._KNOWN_PROVIDER_KEYS}"
    norm = cp._normalize_custom_provider_entry(entry, provider_key="agentgateway")
    assert norm["base_url"] == "https://scarlet:9443/v1" and norm["ssl_ca_cert"].endswith("/ca-bundle.pem")
    assert set(norm["models"]) == GATEWAY_MODELS and "api_key" not in entry
    os.environ["HERMES_HOME"] = str(home)
    from hermes_cli import runtime_provider_custom as rpc

    found = rpc._get_named_custom_provider("custom:agentgateway")
    assert found and found["base_url"] == "https://scarlet:9443/v1"
    assert found["key_cmd"].endswith("read op://private/agent-gateway-api-key/password")


def test_shell_hook_spec_matches_guarded_tools() -> None:
    from agent import shell_hooks

    spec = shell_hooks._parse_single_entry("pre_tool_call", 0, {
        "matcher": "terminal|read_file|search_files|write_file|patch", "command": f"python3 {HOOK}",
        "timeout": 15, "fail_closed": True})
    assert spec is not None and spec.fail_closed is True
    for tool in ("terminal", "read_file", "search_files", "write_file", "patch"):
        assert spec.matches_tool(tool), tool
    assert not spec.matches_tool("terminal_x") and not spec.matches_tool("web_search")


def _run_hook(tool: str, args: dict, home: Path = HOME, raw: str | None = None) -> dict:
    payload = raw if raw is not None else json.dumps({"hook_event_name": "pre_tool_call", "tool_name": tool, "tool_input": args})
    out = subprocess.run([sys.executable, str(HOOK)], input=payload, capture_output=True, text=True,
                         env={**os.environ, "HERMES_HOME": str(home)}).stdout
    from agent import shell_hooks

    return shell_hooks._parse_response("pre_tool_call", out) or {}


def test_hook_blocks_and_allows_as_hermes_parses_it() -> None:
    blocked = [("terminal", {"command": "rm -rf ~"}), ("terminal", {"command": "git push origin main"}),
               ("terminal", {"command": "cat ~/.aws/credentials"}), ("read_file", {"path": "~/.ssh/id_ed25519"}),
               ("write_file", {"path": ".env", "content": "x"}),
               ("patch", {"mode": "replace", "path": ".env.production", "old_string": "a", "new_string": "b"}),
               ("patch", {"mode": "patch", "patch": "*** Begin Patch\n*** Update File: src/ok.py\n*** Move File: a.txt -> ~/.ssh/authorized_keys2\n*** End Patch"}),
               ("terminal", {"command": "terraform destroy"})]
    allowed = [("terminal", {"command": "ls -la"}), ("read_file", {"path": "src/main.py"}),
               ("write_file", {"path": "README.md", "content": "x"}), ("search_files", {"pattern": "x", "path": "src"}),
               ("patch", {"mode": "patch", "patch": "*** Begin Patch\n*** Update File: src/ok.py\n*** End Patch"}),
               ("web_search", {"query": "x"})]
    for tool, args in blocked:
        assert _run_hook(tool, args).get("action") == "block", f"expected block: {tool} {args}"
    for tool, args in allowed:
        assert _run_hook(tool, args) == {}, f"expected allow: {tool} {args}"


def test_hook_fails_closed() -> None:
    with tempfile.TemporaryDirectory() as empty:
        assert _run_hook("terminal", {"command": "ls"}, home=Path(empty)).get("action") == "block"
    assert _run_hook("", {}, raw="not json").get("action") == "block"


def test_v4a_header_regexes_match_hermes() -> None:
    try:
        from tools import file_tools
    except Exception as exc:  # noqa: BLE001 — heavy import; report but don't fail on env issues
        print(f"  (skipped parity check: {exc})")
        return
    src = HOOK.read_text()
    for rx in (file_tools._V4A_SINGLE_HEADER_RE, file_tools._V4A_MOVE_HEADER_RE):
        assert rx.pattern in src.replace("\\\\", "\\") or repr(rx.pattern)[1:-1] in src, f"drift from Hermes: {rx.pattern}"


def test_soul_md_loads_under_hermes_scanner() -> None:
    from agent import prompt_builder as pb

    text = (HOME / "SOUL.md").read_text()
    assert pb._scan_context_content(text, "SOUL.md", user_authored=True) == text, "user-authored SOUL.md must load"
    findings = pb._scan_for_threats(text, scope="context")
    print(f"  SOUL.md injection-pattern findings (warn-only for your own HERMES_HOME): {findings or 'none'}")


def test_skills_valid_and_no_builtin_collisions() -> None:
    from hermes_cli.commands import COMMAND_REGISTRY

    builtin = {c.name for c in COMMAND_REGISTRY} | {a for c in COMMAND_REGISTRY for a in c.aliases}
    names = []
    for f in sorted((HOME / "skills").rglob("SKILL.md")):
        head = f.read_text().split("\n---", 1)[0]
        m = re.search(r"^name: (\S+)$", head, re.M)
        assert m and "\ndescription:" in head and m.group(1) == f.parent.name, f"bad frontmatter: {f}"
        names.append(m.group(1))
    assert len(names) == len(set(names)) == 22, names
    assert not set(names) & builtin, f"shadows built-in slash commands: {set(names) & builtin}"


def test_no_secrets_in_tracked_config() -> None:
    install = (ROOT / "install.sh").read_text()
    listed = re.findall(r"CONFIG_FILES=\(([^)]*)\)", install)[0]
    for rel in (".env", "config.yaml", "auth.json", "state.db"):
        assert rel not in listed.split(), f"{rel} must never be copied"
    for f in [p for p in ROOT.rglob("*") if p.is_file() and p.suffix in {".md", ".yaml", ".sh", ".py", ".json", ".mjs"}]:
        if f.name in ("test_config.py",):
            continue
        assert not SECRETISH.search(f.read_text(errors="ignore")), f"secret-like value in {f.relative_to(ROOT)}"


if __name__ == "__main__":
    failures = 0
    for name, fn in sorted((n, f) for n, f in list(globals().items()) if n.startswith("test_")):
        try:
            fn()
            print(f"PASS {name}")
        except Exception as exc:  # noqa: BLE001 — report every failing check
            failures += 1
            print(f"FAIL {name}: {type(exc).__name__}: {exc}")
    sys.exit(1 if failures else 0)
