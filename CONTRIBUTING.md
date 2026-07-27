# Contributing to ExUnit Atlas

Thank you for helping improve ExUnit Atlas.

## Before opening an issue

- Search existing issues to avoid duplicates.
- Use a minimal reproduction when reporting a bug.
- Include the Elixir and OTP versions from `elixir --version`.
- Explain whether the suite is async and whether the report was still written.
- Remove secrets and private application data from reports and stacktraces.

For usage questions, use GitHub Discussions when it is enabled. Use an issue
when the behavior appears to be a defect or the documentation is incomplete.

## Development setup

The verified baseline is Elixir 1.14.4 on OTP 25.

```console
git clone https://github.com/YOUR_GITHUB_USERNAME/ex_unit_atlas.git
cd ex_unit_atlas
mix deps.get
mix test
```

The repository intentionally has no runtime dependencies. ExDoc is a
development-only dependency.

## Required checks

Run the same checks as CI before opening a pull request:

```console
mix format --check-formatted
mix test
mix docs --warnings-as-errors
mix hex.build
```

Generated `doc/`, `_build/`, `deps/`, package tarballs, and
`ex_unit_atlas_report/` must not be committed.

## Testing changes

- Add unit tests for normalization, encoding, or rendering behavior.
- Use the isolated fixture project for formatter lifecycle behavior.
- Verify failed suites in a child OS process so their exit status can be
  asserted safely.
- Add or update a golden report only when the public schema intentionally
  changes.
- Preserve the async ownership stress test when changing recorder behavior.

Changes affecting failure handling must demonstrate that the original failure
kind, reason, message, and useful user stacktrace frame remain intact.

## Design expectations

Keep the public surface small. A contribution should preserve these invariants:

- ExUnit remains the test framework.
- Atlas never replaces assertions.
- Instrumented blocks execute exactly once.
- Concurrent test events never cross owners.
- Reports remain deterministic and JSON-safe.
- HTML remains static, self-contained, and accessible without a server.
- New runtime dependencies require strong justification.

Please discuss broad DSL additions, schema-breaking changes, or new
integrations in an issue before implementing them.

## Pull requests

Keep pull requests focused and explain:

1. the user problem;
2. the chosen behavior;
3. tests added or changed;
4. public schema or compatibility impact;
5. documentation updates.

Do not include unrelated formatting or refactoring.

## Commit messages

Use concise imperative subjects, for example:

```text
preserve interrupted item errors
document umbrella project setup
```

## Conduct and security

All contributors must follow [CODE_OF_CONDUCT.md](CODE_OF_CONDUCT.md).
Do not disclose security vulnerabilities in public issues; follow
[SECURITY.md](SECURITY.md).
