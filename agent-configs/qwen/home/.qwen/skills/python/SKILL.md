---
name: python
description: "Python 3.12 apps, APIs, scripts and automation — uv, typing, pydantic, ruff, pytest, security"
---

# Python 3.12

## Project
- `uv` for envs/deps (`uv init`, `uv add`, `uv run`); `pyproject.toml` single source; lockfile committed.
- `src/<package>/` layout, `snake_case` modules, `tests/` mirrors package.
- `ruff` (lint + format, rules `E,F,I,B,UP,S,SIM,RUF`), `mypy --strict` or `pyright` for libraries/services.

## Idioms
- Full type hints; `pydantic` v2 models for external data and `pydantic-settings` for config (env vars, `SecretStr` for secrets).
- Explicit exceptions — no bare `except:`; `raise … from err`; log with `logging`/`structlog`, never print secrets.
- `pathlib`, `dataclasses(slots=True)` for internal records, context managers for resources.
- HTTP: `httpx` with timeouts; APIs: FastAPI with pydantic models, dependency-injected auth.
- AWS: `boto3` with default credential chain (run via `op plugin run --` locally); paginators; retries via `botocore.config.Config`.
- Security: `subprocess` with list args (never `shell=True` on user input), parameterised SQL, `secrets` module for tokens, `yaml.safe_load`, no `pickle` on untrusted data.

## Tests
`pytest` with fixtures and `@pytest.mark.parametrize` (table-driven); `pytest-asyncio` for async; `moto` for AWS.

## Validate
`uv run ruff check . && uv run ruff format --check . && uv run pytest -q` · `uv run mypy src` · `pip-audit`
