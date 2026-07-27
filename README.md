# ExUnit Atlas

[![Quality](https://github.com/lukivan8/ex_unit_atlas/actions/workflows/ci.yml/badge.svg)](https://github.com/lukivan8/ex_unit_atlas/actions/workflows/ci.yml)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](https://github.com/lukivan8/ex_unit_atlas/blob/main/LICENSE)

ExUnit Atlas turns ordinary ExUnit tests into a readable map of the behavior
your application guarantees.

It is not a new test framework. ExUnit remains responsible for tests,
assertions, failures, stacktraces, terminal output, and exit codes. Atlas adds
three small annotations—`step`, `show`, and `check`—and generates:

```text
ex_unit_atlas_report/
├── report.json
└── index.html
```

The HTML report is a self-contained document with no server, JavaScript,
external assets, or frontend build step.

## Why Atlas?

Test names are useful, but a test often guarantees more than its name can say.
Atlas lets the test body expose those guarantees without replacing familiar
ExUnit structure:

| ExUnit | Atlas interpretation |
| --- | --- |
| module or file | behavior group |
| `describe` | behavior section |
| `test` | scenario |
| `step` | meaningful setup or action |
| `show` | bounded preview of data flowing through the scenario |
| `check` | named guarantee |
| ExUnit result | scenario status |

The resulting report is meant to be read from top to bottom as business
behavior, while technical metadata remains available when needed.

## Installation

Add Atlas as a test-only dependency:

```elixir
def deps do
  [
    {:ex_unit_atlas, "~> 0.2.0", only: :test, runtime: false}
  ]
end
```

Run `mix deps.get`.

In `test/test_helper.exs`, replace the existing `ExUnit.start()` call with:

```elixir
ExUnit.start(
  formatters: [
    ExUnit.CLIFormatter,
    ExUnitAtlas.Formatter
  ]
)
```

Keep the standard CLI formatter. Atlas complements it; it does not print the
normal test results.

## Usage

Add `use ExUnitAtlas` after `use ExUnit.Case` or your project-specific case
template:

```elixir
defmodule Shop.SaleTest do
  use ExUnit.Case, async: true
  use ExUnitAtlas

  describe "Sales" do
    test "cash sales are fiscalized" do
      sale =
        step "Create a completed cash sale" do
          %{payment_type: :cash, status: :completed}
        end
        |> show("Created sale")

      check "The completed cash sale is eligible for fiscalization" do
        assert sale.payment_type == :cash
        assert sale.status == :completed
      end
    end
  end
end
```

Run tests normally:

```console
mix test
```

Open `ex_unit_atlas_report/index.html` in a browser, or consume
`ex_unit_atlas_report/report.json` from another tool.

## Showing data as it flows

`show/2` records a bounded `inspect` preview and returns the original value, so
it fits naturally into pipelines:

```elixir
order
|> calculate_totals()
|> show("Order after totals")
|> apply_discount()
|> show("Order after discount")
|> persist()
```

The report displays each preview between the surrounding steps and checks. It
does not serialize the original term: collections, strings, and the final
preview are limited to keep reports readable.

Do not show credentials, tokens, personal data, or other secrets. Report files
are often retained as CI artifacts.

## Choosing useful annotations

Use a `step` for preparation or an action that carries business meaning. Use a
`check` to name a guarantee and keep regular `assert` and `refute` expressions
inside it.

Do not add a step only because every scenario appears to need one. This is
perfectly valid:

```elixir
test "disabled fiscalization overrides the request" do
  check "Fiscalization remains disabled" do
    refute should_fiscalize?(request, %{fiscalization_type: :disabled})
  end
end
```

The report becomes valuable when names explain behavior—not when every line of
test code receives a label.

## Runtime semantics

- Instrumented blocks execute exactly once.
- Their return values are returned unchanged.
- `show` returns the exact input value and records only a bounded string preview.
- `error`, `exit`, and `throw` retain their original reason and stacktrace.
- Assertion messages and useful user frames remain visible.
- Concurrent tests keep independent, ordered item streams.
- Passing and failing suites both produce reports.
- ExUnit keeps control of terminal output and the process exit status.
- Without `ExUnitAtlas.Formatter`, blocks still execute normally but no report
  is generated.

## Current limitations

- Nested `step`, `show`, and `check` items are rejected.
- The output directory is fixed to `ex_unit_atlas_report`.
- Skipped and excluded tests are omitted from schema version 2.
- Logger output is not captured; use `show` for intentional data previews.
- Atlas does not automatically register its formatter.

## Documentation

- [Getting started](docs/getting-started.md)
- [Report format](docs/report-format.md)
- [Architecture](docs/architecture.md)
- [ExUnit formatter contract](docs/exunit-integration.md)
- [Roadmap](docs/roadmap.md)
- [`ExUnitAtlas` API](https://hexdocs.pm/ex_unit_atlas/ExUnitAtlas.html)

## Requirements

- Elixir 1.14 or later
- OTP 25 or later is the currently verified baseline
- No runtime dependencies

## Contributing

Bug reports and focused improvements are welcome. Read
[CONTRIBUTING.md](CONTRIBUTING.md) before opening a pull request. By
participating, you agree to follow the [Code of Conduct](CODE_OF_CONDUCT.md).

For release validation and publication, see [RELEASING.md](RELEASING.md).

## License

ExUnit Atlas is available under the
[MIT License](https://opensource.org/license/mit).
