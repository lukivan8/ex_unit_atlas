# ExUnit formatter contract

ExUnit Atlas was initially verified on Elixir 1.14.4 and OTP 25. It relies on
the public `ExUnit.Formatter` contract rather than ExUnit runner internals.

## Observed lifecycle

An ExUnit formatter is a GenServer which receives these events through casts:

1. `suite_started`
2. `module_started`
3. `test_started`
4. `test_finished`
5. `module_finished`
6. `suite_finished`

The `test_started` and `test_finished` events contain an `ExUnit.Test`
structure. Atlas uses the following fields:

- `name`
- `module`
- `state`
- `time`
- `tags.file`
- `tags.line`
- `tags.describe`

Captured logs are available through `test.logs` in the verified runtime, but
they are deliberately excluded from the report. Schema version 2 uses explicit
`show` items instead, avoiding unrelated Logger noise and implicit capture.

## Test ownership

The formatter contract does not expose the test process PID. Atlas therefore
does not use a PID as the identity of a test and does not inspect ExUnit's
process dictionary.

Instead, `use ExUnitAtlas` registers a setup callback. The callback executes in
the test process and derives the internal key:

```elixir
{context.module, context.test}
```

The formatter derives the equivalent key from the completed test:

```elixir
{test.module, test.name}
```

This key is internal and never appears in the public report.

## Concurrency verification

The integration fixture runs two separate `async: true` modules with the same
human-readable test name. A barrier forces their execution to overlap, and
their Atlas items are deliberately interleaved.

The fixture is repeated 50 times. Every run must produce:

```text
Test A → A1, A2
Test B → B1, B2
```

No item may cross owners, disappear, or change order. This test guards the
central concurrency assumption behind Atlas.
