"""Offline checks for the grok-cli config (stdlib only):  python3 tests/test_config.py"""
from __future__ import annotations

import json
import re
import subprocess
import sys
import tempfile
from pathlib import Path

sys.dont_write_bytecode = True
ROOT = Path(__file__).resolve().parent.parent
HOME = ROOT / "home" / ".grok"
GATEWAY_MODELS = {"deepseek-flash", "claude-sonnet-5", "openrouter/openai/gpt-6-sol", "openrouter/anthropic/claude-opus-5-5"}
SECRETISH = re.compile(r"(?i)(sk-[A-Za-z0-9-]{12,}|xai-[A-Za-z0-9]{12,}|\b[a-f0-9]{40,}\b|bearer\s+[A-Za-z0-9._-]{20,})")


def test_fragment_points_at_gateway() -> None:
    frag = json.loads((HOME / "user-settings.fragment.json").read_text())
    assert frag["baseURL"] == "https://scarlet:9443/v1"
    assert set(frag["models"]) == GATEWAY_MODELS and frag["defaultModel"] in frag["models"]
    assert "apiKey" not in frag


def test_configure_settings_removes_key_and_replaces_models() -> None:
    with tempfile.TemporaryDirectory() as d:
        target = Path(d) / "user-settings.json"
        target.write_text(json.dumps({"baseURL": "https://api.x.ai/v1", "apiKey": "dummy-value", "defaultModel": "grok-code-fast-1",
                                      "models": ["grok-4", "grok-code-fast-1"], "settingsVersion": 2, "custom": 1}))
        out = subprocess.run([sys.executable, str(ROOT / "lib" / "configure-settings.py"), d, str(HOME / "user-settings.fragment.json")],
                             capture_output=True, text=True, check=True).stdout
        data = json.loads(target.read_text())
        assert "apiKey" not in data and data["custom"] == 1 and set(data["models"]) == GATEWAY_MODELS
        assert data["settingsVersion"] >= 2 and (target.stat().st_mode & 0o777) == 0o600
        assert "dummy-value" not in out, "must never print the key"


def test_wrapper_sets_gateway_env() -> None:
    sh = (HOME / "grok-env.sh").read_text()
    for needle in ('GROK_BASE_URL="$_GROK_GATEWAY"', "unset MORPH_API_KEY", "NODE_EXTRA_CA_CERTS=", "--require $home/grok-preload.cjs",
                   "op read", "command grok"):
        assert needle in sh, needle


def test_no_secrets_in_config() -> None:
    for f in [p for p in HOME.rglob("*") if p.is_file()] + [ROOT / "install.sh"]:
        assert not SECRETISH.search(f.read_text(errors="ignore")), f"secret-like value in {f.relative_to(ROOT)}"


def test_install_never_copies_runtime_state() -> None:
    files = re.findall(r"CONFIG_FILES=\(([^)]*)\)", (ROOT / "install.sh").read_text())[0].split()
    assert not {"user-settings.json", "settings.json", "hooks", "skills"} & set(files)


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
