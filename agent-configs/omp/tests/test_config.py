"""Offline checks for the omp config, driven through the installed omp binary where possible.

omp runs against a throwaway HOME/agent dir with PI_OFFLINE=1, so nothing under ~/.omp is touched.
    make test        (= python3 tests/test_config.py)
"""
from __future__ import annotations

import json
import os
import re
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path

sys.dont_write_bytecode = True
ROOT = Path(__file__).resolve().parent.parent
AGENT = ROOT / "home" / ".omp" / "agent"
GATEWAY_IDS = {"deepseek-flash", "claude-sonnet-5", "openrouter/openai/gpt-6-sol", "openrouter/anthropic/claude-opus-5-5"}
# Chat roles from omp's model browser (packages/tui/src/overlays/model-browser.ts, omp 18.18.3).
CHAT_ROLES = {"default", "smol", "slow", "vision", "plan", "commit", "tiny", "memory", "task", "advisor", "widget"}
# Built-in tools (omp --help "Available Tools") + those the bundled agents use.
TOOLS = {"read", "bash", "edit", "write", "grep", "glob", "find", "ast_grep", "lsp", "python", "notebook",
         "browser", "computer", "task", "todo", "web_search", "ask"}
AGENT_KEYS = {"name", "description", "tools", "spawns", "model", "thinkingLevel", "output"}
SECRETISH = re.compile(r"(?i)(sk-[A-Za-z0-9-]{12,}|\b[a-f0-9]{40,}\b|bearer\s+[A-Za-z0-9._-]{20,})")


def _omp(home: Path, *args: str, env: dict | None = None) -> subprocess.CompletedProcess:
    base = {k: v for k, v in os.environ.items() if not k.endswith(("_API_KEY", "_TOKEN"))}
    base.update({"HOME": str(home), "PI_OFFLINE": "1", "PI_CONFIG_DIR": str(home / ".omp"),
                 "PI_CODING_AGENT_DIR": str(home / "agent")}, **(env or {}))
    return subprocess.run(["omp", *args], env=base, capture_output=True, text=True, timeout=120)


def _home() -> Path:
    home = Path(tempfile.mkdtemp(prefix="omp-test-"))
    (home / "agent").mkdir()
    shutil.copy(AGENT / "models.yml", home / "agent" / "models.yml")
    shutil.copytree(AGENT / "guard", home / "agent" / "guard")
    return home


def _selectors(home: Path) -> dict[str, dict]:
    run = _omp(home, "models", "agentgateway", "--json")
    assert run.returncode == 0, run.stderr[-400:]
    return {m["selector"]: m for m in json.loads(run.stdout)["models"]}


def _frontmatter(path: Path) -> dict:
    import ast  # tiny YAML subset: the build writes block lists and scalars only
    text = path.read_text().split("\n---\n", 1)[0].removeprefix("---\n")
    data, key = {}, None
    for line in text.splitlines():
        if line.startswith("- ") and key:
            data.setdefault(key, []).append(line[2:].strip().strip('"\''))
        elif ":" in line:
            key, _, val = line.partition(":")
            val = val.strip()
            data[key] = [] if val == "" else (ast.literal_eval(val) if val[:1] in "'\"" else val)
    return data


def test_models_yml_loads_with_omp() -> None:
    home = _home()
    sel = _selectors(home)
    assert {m["id"] for m in sel.values()} == GATEWAY_IDS
    assert sel["agentgateway/deepseek-flash"]["contextWindow"] == 128000, "contextWindow override not applied"


def test_api_key_is_read_from_env_var_name() -> None:
    home = _home()
    run = _omp(home, "token", "agentgateway", env={"AGENTGATEWAY_API_KEY": "dummy-env-value"})
    assert run.stdout.strip().splitlines()[-1] == "dummy-env-value", "omp must resolve apiKey as an env-var name"


def test_settings_apply_via_omp_config_set() -> None:
    home = _home()
    sel = _selectors(home)
    settings = {k: v for k, v in json.loads((AGENT / "config.settings.json").read_text()).items() if not k.startswith("_")}
    assert set(settings["modelRoles"]) <= CHAT_ROLES, set(settings["modelRoles"]) - CHAT_ROLES
    assert set(settings["modelRoles"].values()) <= set(sel), set(settings["modelRoles"].values()) - set(sel)
    for key, value in settings.items():
        run = _omp(home, "config", "set", key, value if isinstance(value, str) else json.dumps(value))
        assert run.returncode == 0 and "Set" in run.stdout, f"{key}: {run.stdout[-200:]}{run.stderr[-200:]}"


def test_agents_use_valid_keys_tools_and_models() -> None:
    home = _home()
    sel = _selectors(home)
    names = set()
    for f in sorted((AGENT / "agents").glob("*.md")):
        fm = _frontmatter(f)
        names.add(fm["name"])
        assert set(fm) <= AGENT_KEYS, f"{f.name}: unknown keys {set(fm) - AGENT_KEYS}"
        assert set(fm.get("tools", [])) <= TOOLS, f"{f.name}: unknown tools {set(fm.get('tools', [])) - TOOLS}"
        for m in fm["model"]:
            assert (m.startswith("@") and m[1:] in CHAT_ROLES) or m in sel, f"{f.name}: model {m}"
    assert names == {"explorer", "reviewer", "planner", "developer", "sre", "architect", "security"}
    for f in (AGENT / "agents").glob("*.md"):
        assert set(_frontmatter(f).get("spawns", [])) <= names


def test_guard_extension_loads_in_omp() -> None:
    home = _home()
    run = _omp(home, "models", "-e", str(AGENT / "extensions" / "guardrails.ts"), "agentgateway")
    assert run.returncode == 0 and "Failed to load extension" not in run.stdout + run.stderr, run.stderr[-400:]


def test_guard_shim_decisions() -> None:
    cases = [("bash", {"command": "rm -rf ~"}, "deny"), ("bash", {"command": "git push origin main"}, "ask"),
             ("bash", {"command": "ls -la"}, "allow"), ("read", {"path": "~/.ssh/id_ed25519"}, "deny"),
             ("write", {"path": "README.md", "content": "x"}, "allow"),
             ("edit", {"path": ".env", "old_string": "a", "new_string": "b"}, "deny"),
             ("edit", {"path": "a.py", "edits": [{"rename": "secrets/.env"}]}, "deny"),
             ("edit", {"input": "*** Begin Patch\n*** Update File: x/.env\n*** End Patch"}, "deny"),
             ("python", {"code": "import os; os.system('rm -rf ~')"}, "deny"), ("todo", {"items": []}, "allow")]
    for tool, inp, want in cases:
        run = subprocess.run([sys.executable, str(AGENT / "guard" / "omp_guard.py")],
                             input=json.dumps({"toolName": tool, "input": inp}), capture_output=True, text=True)
        assert json.loads(run.stdout)["decision"] == want, f"{tool} {inp}: {run.stdout}"


def test_no_secrets_in_config() -> None:
    install = (ROOT / "install.sh").read_text()
    listed = re.findall(r"CONFIG_FILES=\(([^)]*)\)", install)[0]
    assert ".db" not in listed and "sessions" not in listed
    for f in AGENT.rglob("*"):
        if f.is_file() and f.suffix in {".md", ".yml", ".json", ".sh", ".ts", ".py"} and f.name != "guardrails.json":
            assert not SECRETISH.search(f.read_text(errors="ignore")), f"secret-like value in {f.relative_to(ROOT)}"


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
