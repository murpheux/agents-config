---
name: golang
description: "Go 1.26 services/CLIs — project layout, errors, context, concurrency, HTTP servers, testing and tooling"
---

# Go

## Layout
`cmd/<app>/main.go` (wiring only) · `internal/<pkg>/` (lowercase single-word packages, `snake_case.go` files) · `go.mod` pinned toolchain.

## Idioms
- Stdlib first (`net/http` with 1.22+ routing patterns, `log/slog`, `encoding/json`, `database/sql`); add deps only when they clearly win.
- Errors: wrap with `fmt.Errorf("op: %w", err)`; inspect with `errors.Is`/`errors.As`; sentinel or typed errors for callers; never ignore returned errors.
- `context.Context` is the first param of anything doing I/O; respect cancellation; no contexts in structs.
- Concurrency: `errgroup` for fan-out with cancellation; bounded worker pools; close channels from the sender; `-race` in tests.
- Accept interfaces, return structs; small interfaces defined where consumed.
- HTTP servers: set `ReadHeaderTimeout`, `ReadTimeout`, `WriteTimeout`, `IdleTimeout`; `http.MaxBytesReader`; graceful shutdown on SIGTERM.
- Config from env via a typed struct with validation; secrets never logged (`slog` `LogValuer` redaction).
- Security: `crypto/rand` not `math/rand` for secrets; parameterised SQL; `html/template` for HTML; `govulncheck`.

## Tests
Table-driven with `t.Run`, `t.Parallel()` where safe, `httptest`, `testing/fstest`, fuzz tests for parsers.

## Validate
`go build ./... && go vet ./... && go test -race ./...` · `golangci-lint run` · `govulncheck ./...`
