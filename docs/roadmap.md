# Roadmap

ExUnit Atlas 0.1 focuses on one complete path:

```text
ExUnit → step/check → normalized report → JSON and static HTML
```

The roadmap is intentionally conservative. New features should make behavior
reports clearer without changing the semantics of ordinary ExUnit tests.

## Current release: 0.1

- Named `step/2` and `check/2` blocks
- Async-safe event ownership
- Preserved ExUnit failures and stacktraces
- Stable JSON schema version 1
- Minimal static HTML report
- Reports for passing and failing suites
- Zero runtime dependencies

## Candidates for a future minor release

- Configurable output directory
- ExUnit tag display
- Source links for common Git hosts
- A documented CI artifact example
- Broader tested Elixir and OTP compatibility

These are candidates, not commitments. Each should be justified by real usage.

## Explicit non-goals

- A replacement for ExUnit
- A custom assertion system
- Automatic assertion or source-code analysis
- A separate scenario DSL
- Database snapshots or diffs
- HTTP, Logger, or Telemetry tracing
- A Phoenix or LiveView dependency
- A Node.js build pipeline
- Hosted report storage

## Design constraints

Any accepted feature must:

1. Preserve ExUnit's error, stacktrace, output, and exit-code behavior.
2. Keep concurrent test events isolated.
3. Keep report data JSON-safe and deterministic.
4. Avoid exposing internal ownership keys.
5. Work without a web server or frontend toolchain.
