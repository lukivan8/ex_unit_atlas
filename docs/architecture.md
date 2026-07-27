# Architecture

ExUnit Atlas is intentionally small. The public API consists of
`ExUnitAtlas`, `step/2`, `show/2`, `check/2`, and the formatter users register
with ExUnit.

## Data flow

```text
test process
  └─ step/show/check
       └─ Recorder
            └─ Formatter receives test_finished
                 └─ Report normalization
                      ├─ report.json
                      └─ index.html
```

## Components

### `ExUnitAtlas`

Provides `use ExUnitAtlas`, imports the public instrumentation API, and
registers a setup callback that derives the internal owner key from the public
ExUnit context.

Each macro:

1. validates its name;
2. records the start time;
3. executes the block exactly once;
4. records success or failure;
5. returns the original result or re-raises the original failure.

`show/2` is a regular pipe-friendly function. It creates a bounded `inspect`
preview, records that string, and returns the original term unchanged.

### Recorder

A named GenServer which stores one ordered item stream per owner key. Sequence
numbers are internal. Taking a completed test's items atomically removes that
owner from state.

If a test ends while an item is open, the recorder finalizes it as
`interrupted`. If the recorder is unavailable, instrumentation becomes a
best-effort no-op so it cannot mask user code or test failures.

### Formatter

Receives public ExUnit formatter events. On `test_finished`, it associates the
test with its recorded items. On `suite_finished`, it builds the normalized
report and writes both output formats.

It does not replace the standard ExUnit CLI formatter, print individual test
results, or control the suite exit status.

### Report normalization

Converts ExUnit structures and recorder items into a deterministic,
JSON-safe tree. Internal PIDs, references, functions, structs, and ownership
keys never enter the report.

### JSON encoding

A strict encoder for the limited normalized data model. It accepts only null,
booleans, integers, UTF-8 strings, lists, and maps with string keys. Output is
written through a temporary file followed by rename.

### HTML rendering

Renders the same normalized report as a self-contained HTML document. It has
no external assets, JavaScript, server requirement, or build step. All
user-controlled strings are escaped.

## Invariants

- Instrumented blocks execute exactly once.
- Return values are not transformed.
- Shown terms are reduced to bounded strings before entering recorder state.
- `error`, `exit`, and `throw` preserve kind, reason, and stacktrace.
- Items remain ordered and isolated between async tests.
- Reports are written after both successful and failed suites.
- Generated files never contain arbitrary Elixir terms.
