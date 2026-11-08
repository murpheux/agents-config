"""Offline checks for the Tau config, run with Tau's own Python so Tau's real schema/classes are used.

    make test        (= <tau-venv>/bin/python -m pytest -q tests/  or  python tests/test_config.py)
"""
from __future__ import annotations

import importlib.util
import json
import os
import re
import shutil
import sys
import tempfile
from pathlib import Path

sys.dont_write_bytecode = True  # never leave __pycache__ in the config tree
ROOT = Path(__file__).resolve().parent.parent
HOME = ROOT / "home" / ".tau"
GATEWAY_MODELS = {"deepseek-flash", "claude-sonnet-5", "openrouter/openai/gpt-6-sol", "openrouter/anthropic/claude-opus-5-5"}
SECRETISH = re.compile(r"(?i)(sk-[A-Za-z0-9-]{12,}|\b[a-f0-9]{40,}\b|bearer\s+[A-Za-z0-9._-]{20,})")


def test_catalog_loads_with_tau_schema() -> None:
    from tau_coding import catalog_loader

    with tempfile.TemporaryDirectory() as home:
        shutil.copy(HOME / "catalog.toml", Path(home) / "catalog.toml")
        os.environ["TAU_HOME"] = home
        entry = next(e for e in catalog_loader.effective_catalog() if e.name == "agentgateway")
    assert entry.base_url == "https://scarlet:9443/v1"
    assert entry.api_key_env == "AGENTGATEWAY_API_KEY"
    assert entry.credential_name is None, "credential_name makes Tau prefer plaintext credentials.json"
    assert set(entry.models) <= GATEWAY_MODELS and entry.default_model in entry.models


def test_providers_fragment_defaults_to_gateway() -> None:
    frag = json.loads((HOME / "providers.fragment.json").read_text())
    assert frag["default_provider"] == "agentgateway"
    assert frag["provider_preferences"]["agentgateway"]["default_model"] in GATEWAY_MODELS


def _guard_handler(tau_home: Path):
    from tau_coding.extensions import ToolCallHookEvent

    os.environ["TAU_HOME"] = str(tau_home)
    spec = importlib.util.spec_from_file_location("tau_guardrails_ext", HOME / "extensions" / "guardrails.py")
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    handlers = {}

    class _API:
        def on(self, event, handler=None):
            def register(h):
                handlers[event] = h
                return h
            return register(handler) if handler else register

    module.setup(_API())
    return lambda tool, args: handlers["tool_call"](ToolCallHookEvent(tool_name=tool, arguments=args), None)


def test_guardrails_extension_blocks_and_allows() -> None:
    call = _guard_handler(HOME)
    blocked = [("bash", {"command": "rm -rf ~"}), ("bash", {"command": "git push origin main"}),
               ("bash", {"command": "cat ~/.aws/credentials"}), ("read", {"path": "~/.ssh/id_ed25519"}),
               ("edit", {"path": ".env", "edits": []}), ("bash", {"command": "terraform destroy"})]
    allowed = [("bash", {"command": "ls -la"}), ("read", {"path": "src/main.py"}),
               ("write", {"path": "README.md", "content": "x"}), ("grep", {"pattern": "x"})]
    for tool, args in blocked:
        result = call(tool, args)
        assert result is not None and result.block, f"expected block: {tool} {args}"
    for tool, args in allowed:
        assert call(tool, args) is None, f"expected allow: {tool} {args}"


def test_guardrails_extension_fails_closed_without_guard() -> None:
    with tempfile.TemporaryDirectory() as empty:
        call = _guard_handler(Path(empty))
        for tool in ("bash", "read", "write", "edit"):
            result = call(tool, {"command": "ls", "path": "x"})
            assert result is not None and result.block, f"{tool} must be blocked when the guard is missing"


def test_no_secrets_or_runtime_state_in_config() -> None:
    install = (ROOT / "install.sh").read_text()
    for rel in ("credentials.json", "sessions", "logs", "models-store.json"):
        assert rel not in re.findall(r"CONFIG_FILES=\(([^)]*)\)", install)[0], f"{rel} must never be installed"
    for f in list(HOME.rglob("*.md")) + list(HOME.rglob("*.toml")) + list(HOME.rglob("*.sh")) + list(HOME.rglob("*.json")):
        if any(p in f.parts for p in ("sessions", "logs", "cache", "state")) or f.name in ("credentials.json", "models-store.json", "providers.json"):
            continue  # runtime state: git-ignored, never installed
        assert not SECRETISH.search(f.read_text(errors="ignore")), f"secret-like value in {f.relative_to(ROOT)}"


def test_skills_and_prompts_have_frontmatter() -> None:
    for f in list((HOME / "skills").glob("*/SKILL.md")) + list((HOME / "prompts").glob("*.md")):
        text = f.read_text()
        assert text.startswith("---\n") and "\ndescription:" in text.split("\n---", 1)[0], f"bad frontmatter: {f.name}"
    for f in (HOME / "skills").glob("*/SKILL.md"):
        assert f"name: {f.parent.name}\n" in f.read_text(), f"name != dir: {f}"


if __name__ == "__main__":
    failures = 0
    for name, fn in sorted((n, f) for n, f in globals().items() if n.startswith("test_")):
        try:
            fn()
            print(f"PASS {name}")
        except Exception as exc:  # noqa: BLE001 — report every failing check
            failures += 1
            print(f"FAIL {name}: {exc}")
    sys.exit(1 if failures else 0)
