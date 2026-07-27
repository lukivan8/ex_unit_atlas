# Repository guide for coding agents

ExUnit Atlas is an Elixir library that annotates regular ExUnit tests with
named behavior steps and checks, then writes JSON and static HTML reports.

## Start here

Read these files before changing behavior:

1. `README.md`
2. `docs/architecture.md`
3. `docs/report-format.md`
4. `docs/exunit-integration.md`

## Commands

```console
mix deps.get
mix format --check-formatted
mix test
mix docs --warnings-as-errors
mix hex.build
```

## Non-negotiable invariants

- Never change ExUnit assertion or exit semantics.
- Preserve `error`, `exit`, and `throw` kind, reason, and stacktrace.
- Execute every instrumented block exactly once.
- Never mix events from concurrent tests.
- Keep schema output deterministic and JSON-safe.
- Escape all user-controlled HTML.
- Do not add a runtime dependency without explicit justification.
- Do not add HTML complexity, JavaScript, or a frontend build by default.

Formatter integration behavior belongs in the isolated fixture suite under
`test/fixtures/integration`. Failing suites must be tested as child OS
processes.

Do not publish to Hex, create releases, or push branches unless the user
explicitly requests it.
