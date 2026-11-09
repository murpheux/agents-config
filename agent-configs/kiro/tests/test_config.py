"""Offline structure checks for the Kiro CLI config (skeleton). No network, nothing under ~/.kiro is touched.
    make test        (= python3 tests/test_config.py)
"""
from __future__ import annotations

import json
import re
import sys
from pathlib import Path

sys.dont_write_bytecode = True
ROOT = Path(__file__).resolve().parent.parent
HOME = ROOT / "home" / ".kiro"
AGENT_NAMES = {'developer', 'security', 'architect', 'reviewer', 'planner', 'explorer', 'sre'}
SECRETISH = re.compile(r"(?i)(sk-[A-Za-z0-9-]{12,}|\b[a-f0-9]{40,}\b|bearer\s+[A-Za-z0-9._-]{20,})")


def test_layout() -> None:
    for rel in ['settings/cli.json', 'kiro-env.sh', 'hooks/kiro_guard.py', 'agents', 'steering/AGENTS.md']:
        assert (HOME / rel).exists(), f"missing {rel}"


def test_config_parses() -> None:
    json.loads((HOME / "settings/cli.json").read_text())


def test_agents_present() -> None:
    names = {p.stem for p in (HOME / "agents").glob("*.json")}
    assert names == AGENT_NAMES, names ^ AGENT_NAMES


def test_guard_adapter_decisions() -> None:
    import subprocess
    guard = HOME / "hooks"
    if not (guard / "guard.py").exists():
        return  # skeleton: guard.py/guardrails.json arrive with `make build`
    cases = [("bash", {"command": "rm -rf ~"}, "deny"), ("bash", {"command": "ls -la"}, "allow")]
    for tool, inp, want in cases:
        run = subprocess.run([sys.executable, str(guard / "kiro_guard.py")],
                             input=json.dumps({"tool_name": tool, "tool_input": inp}), capture_output=True, text=True)
        blocked = run.returncode != 0 or '"deny"' in run.stdout
        assert blocked == (want == "deny"), f"{tool} {inp}: rc={run.returncode} {run.stdout}{run.stderr}"


def test_no_secrets_in_config() -> None:
    install = (ROOT / "install.sh").read_text()
    listed = re.findall(r"CONFIG_FILES=\(([^)]*)\)", install)[0]
    assert ".db" not in listed and "sessions" not in listed
    for f in HOME.rglob("*"):
        if f.is_file() and f.suffix in {".md", ".json", ".jsonc", ".toml", ".yaml", ".sh", ".ts", ".py"} and f.name != "guardrails.json":
            assert not SECRETISH.search(f.read_text(errors="ignore")), f"secret-like value in {f.relative_to(ROOT)}"


if __name__ == "__main__":
    failures = 0
    for name, fn in sorted((n, f) for n, f in globals().items() if n.startswith("test_")):
        try:
            fn()
            print(f"PASS {name}")
        except Exception as exc:  # noqa: BLE001 - report every failing check
            failures += 1
            print(f"FAIL {name}: {exc}")
    sys.exit(1 if failures else 0)
