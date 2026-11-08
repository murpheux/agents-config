---
name: dotnet
description: "C#/.NET 10 services, APIs, workers and libraries — project structure, async, DI, configuration, EF Core, testing, security, dotnet CLI"
---

# C# / .NET 10

## Structure
```
src/<Company>.<App>.Api/        # ASP.NET Core minimal APIs or controllers
src/<Company>.<App>.Core/       # domain, no infra deps
src/<Company>.<App>.Infrastructure/
tests/<Company>.<App>.*.Tests/  # xUnit
Directory.Build.props           # Nullable=enable, TreatWarningsAsErrors, LangVersion latest, AnalysisLevel latest
Directory.Packages.props        # central package management
global.json                     # SDK pin (10.0.300)
```

## Idioms
- `<Nullable>enable</Nullable>`; no `!` suppression without comment; records for DTOs; `required` members.
- Async end-to-end with `CancellationToken`; never `.Result`/`.Wait()`; `ConfigureAwait(false)` in libraries.
- DI via `Microsoft.Extensions.DependencyInjection`; Options pattern (`IOptions<T>` + `ValidateDataAnnotations().ValidateOnStart()`).
- `ILogger<T>` with structured templates; no secrets in logs.
- HTTP: `IHttpClientFactory` + Polly/`Microsoft.Extensions.Http.Resilience`; timeouts everywhere.
- EF Core: migrations reviewed as code; no `EnsureCreated` in prod; parameterised queries only (`FromSqlInterpolated`).
- Errors: exceptions for exceptional cases, `ProblemDetails` for API errors; `Result` types when failure is expected.
- Security: ASP.NET Core Identity / Entra ID (Microsoft.Identity.Web) — never hand-rolled auth; `[Authorize]` by default with explicit `[AllowAnonymous]`; secrets via user-secrets (dev) and Key Vault/Secrets Manager (prod); Data Protection keys persisted securely; HTTPS + HSTS.

## Tests
xUnit + FluentAssertions (or Shouldly), `[Theory]`/`[InlineData]` for table-driven cases, `WebApplicationFactory` for API tests, Testcontainers for DB integration.

## Validate
`dotnet build -warnaserror` · `dotnet test` · `dotnet format --verify-no-changes` · `dotnet list package --vulnerable --include-transitive`

Use the Microsoft Learn MCP server (when configured) for current .NET API details.
