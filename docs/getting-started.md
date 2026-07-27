# Getting Started

This guide is deliberately explicit so a developer or coding agent can add
ExUnit Atlas to an existing project without guessing.

## Integration checklist

1. Add this dependency to the project's `mix.exs`:

   ```elixir
   {:ex_unit_atlas, "~> 0.2.0", only: :test, runtime: false}
   ```

2. Run `mix deps.get`.

3. Find the existing `ExUnit.start()` in `test/test_helper.exs`. Replace that
   call; do not add a second one. Preserve any formatter the project already
   needs and add Atlas alongside it:

   ```elixir
   ExUnit.start(
     formatters: [
       ExUnit.CLIFormatter,
       ExUnitAtlas.Formatter
     ]
   )
   ```

4. Add `use ExUnitAtlas` after `use ExUnit.Case` in every test module that
   should record behavior:

   ```elixir
   use ExUnit.Case, async: true
   use ExUnitAtlas
   ```

   If the project uses a case template such as `MyApp.DataCase`, add
   `use ExUnitAtlas` after that template instead.

5. Wrap meaningful preparation or actions in `step`, display important
   intermediate data with `show`, and put guaranteed outcomes in `check`. Keep
   existing `assert` and `refute` expressions:

   ```elixir
   result =
     step "Perform the business action" do
       perform_action()
     end
     |> show("Action result")

   check "The business rule holds" do
     assert result.status == :completed
   end
   ```

6. Run `mix test`. The report is generated relative to the project's working
   directory:

   ```text
   ex_unit_atlas_report/report.json
   ex_unit_atlas_report/index.html
   ```

7. Usually add `/ex_unit_atlas_report/` to the consuming project's
   `.gitignore`. Preserve it as a CI artifact when needed.

## Existing project templates

Many Phoenix projects use a case template:

```elixir
defmodule MyApp.OrderTest do
  use MyApp.DataCase, async: true
  use ExUnitAtlas
end
```

The order matters because Atlas registers an ExUnit setup callback. The
project template must establish the ExUnit case first.

Atlas does not require changes to `application/0`, a supervision tree, or
runtime configuration.

## Important behavior

- Keep the standard ExUnit CLI formatter in the formatter list.
- Do not nest `step`, `show`, or `check`.
- Names must be non-empty strings.
- Unannotated tests are included with an empty item list.
- A failing suite writes the report and retains ExUnit's non-zero exit status.
- No application supervision setup is required.
- The output directory is fixed in version 0.2.
- Report names, assertion messages, and stacktraces may contain sensitive
  business or source information; review artifacts before publishing them.
- Values passed to `show` are inspected into bounded strings, but may still
  expose credentials or personal data. Show only artifact-safe values.

## Troubleshooting

### No report is generated

Confirm that `ExUnitAtlas.Formatter` is in the formatter list passed to the
suite's single `ExUnit.start/1` call.

### Steps run but do not appear

Confirm that the test module has `use ExUnitAtlas` after its
`use ExUnit.Case` or case template.

### Normal terminal output disappeared

Add the standard ExUnit CLI formatter back to the formatter list.

### A nested item raises `ArgumentError`

Nesting is intentionally unsupported. Use a linear sequence of sibling
`step`, `show`, and `check` items.
