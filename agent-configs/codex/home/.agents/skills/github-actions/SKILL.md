---
name: github-actions
description: "Writing or reviewing GitHub Actions CI/CD workflows — security hardening, OIDC to clouds, caching, reusable workflows, debugging failed runs"
---

# GitHub Actions

## Hardening (flag deviations)
- Top-level `permissions: {}` (or `contents: read`), grant per job only what's needed (`id-token: write` for OIDC, `pull-requests: write` for comments).
- Pin third-party actions to a full commit SHA with a version comment: `uses: actions/checkout@<sha> # v4.2.2`. Dependabot for `github-actions` ecosystem.
- Cloud auth via OIDC (`aws-actions/configure-aws-credentials` with `role-to-assume`, `azure/login` with federated credentials) — no long-lived cloud keys in secrets.
- Never use `pull_request_target` with checkout of PR head code; treat `github.event.*` text (titles, bodies, branch names) as untrusted — pass via `env:` not inline `${{ }}` in `run:`.
- Environments with required reviewers for prod deploys; `concurrency` groups to prevent overlapping deploys.
- Secret scanning (`ggshield`/gitleaks) and dependency review on PRs.

## Efficiency
`actions/setup-*` with built-in caching (`cache: npm|pip|gradle`, `setup-go` cache, NuGet cache), path filters, matrix only where needed, `timeout-minutes` on every job, reusable workflows (`workflow_call`) for shared pipelines.

## Skeleton
```yaml
name: ci
on: { pull_request: {}, push: { branches: [main] } }
permissions: { contents: read }
concurrency: { group: ci-${{ github.ref }}, cancel-in-progress: true }
jobs:
  test:
    runs-on: ubuntu-latest
    timeout-minutes: 15
    steps:
      - uses: actions/checkout@<sha> # v4
      - run: make lint test
```

## Debugging failures
`gh run list --limit 5` → `gh run view <id> --log-failed` (read-only, safe to auto-approve); or the GitHub MCP server's Actions tools. Reproduce locally with the same `make` target before changing the workflow.
