# Releasing ExUnit Atlas

Publishing changes external state. Perform the final command only with the
package owner's explicit approval.

## Before the first release

1. Confirm that `https://hex.pm/api/packages/ex_unit_atlas` still returns 404.
2. Confirm the version in `mix.exs` and `CHANGELOG.md`.
3. Confirm that package metadata points to
   `https://github.com/lukivan8/ex_unit_atlas`.
4. Ensure the release commit is on `main` and all required checks pass.

## Validate

Run on Elixir 1.14.4 / OTP 25:

```console
mix deps.get
mix format --check-formatted
mix test
mix docs --warnings-as-errors
mix hex.build
mix hex.build --unpack
```

Inspect the unpacked directory. It must contain the library source, `mix.exs`,
README, Getting Started guide, changelog, and license. It must not contain test
fixtures, generated reports, or local build artifacts.

## Publish

Authenticate as the intended Hex package owner:

```console
mix hex.user auth
```

Then publish the package and HexDocs:

```console
mix hex.publish
```

After publication:

1. Open `https://hex.pm/packages/ex_unit_atlas`.
2. Open `https://hexdocs.pm/ex_unit_atlas`.
3. In a clean project, add
   `{:ex_unit_atlas, "~> 0.1.0", only: :test, runtime: false}` and follow the
   README.
4. Tag the exact published commit as `v0.1.0`.
