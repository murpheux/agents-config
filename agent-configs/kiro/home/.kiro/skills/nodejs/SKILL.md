---
name: nodejs
description: "Node.js 22 + TypeScript services, CLIs and libraries — strict TS, biome, ESM, testing, security, package management"
---

# Node.js 22 / TypeScript

## Project
- ESM (`"type": "module"`), `tsconfig` with `strict`, `noUncheckedIndexedAccess`, `exactOptionalPropertyTypes`, `module/moduleResolution: NodeNext`.
- `biome` for lint + format (not prettier/eslint); `kebab-case` file names, `camelCase` identifiers.
- Lockfile committed; `npm ci` in CI; engines field `"node": ">=22"`; pin exact versions for CLIs.

## Idioms
- Validate all external input with `zod` (or valibot) at boundaries; derive types from schemas.
- `async`/`await` with `AbortSignal` timeouts (`AbortSignal.timeout(ms)`); no floating promises.
- Built-ins first: `fetch`, `node:test`, `node:crypto`, `node:fs/promises`, `--env-file` for local dev.
- Errors: typed error classes with `cause`; central error handler in HTTP frameworks (Fastify/Hono/Express 5).
- Logging: `pino` structured, redact auth headers/secrets.
- Security: parameterised queries, `helmet`/secure headers, rate limiting, no `eval`/`new Function`, `child_process.execFile` over `exec`, `npm audit` + lockfile review, avoid unmaintained deps.

## Tests
`vitest` or `node:test`; table-driven with `test.each`; `supertest`/`fetch` against an in-process server.

## Validate
`npx tsc --noEmit` · `npx biome check .` · `npm test` · `npm audit --omit=dev`
