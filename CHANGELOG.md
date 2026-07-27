# Changelog

All notable changes to this project are documented in this file. The project
uses [Semantic Versioning](https://semver.org/).

## Unreleased

- Run ExUnit Atlas against its own test suite as executable documentation.
- Recover the formatter when the recorder becomes unavailable during a suite.
- Verify and upload the generated HTML and JSON report in GitHub Actions.

## 0.2.0 - 2026-07-27

- Add pipe-friendly `show(value, label)` for recording intermediate data.
- Limit inspected collections, strings, and final preview length.
- Display shown values in JSON and static HTML reports.
- Advance the report format to schema version 2.
- Document sensitive-data risks and the choice not to intercept Logger output.

## 0.1.0 - 2026-07-27

First public release.

- Add `step/2` and `check/2` with preserved ExUnit failure semantics.
- Isolate events from concurrently running tests.
- Generate normalized `report.json` after passing and failing suites.
- Generate a minimal static `index.html` grouped by behavior section.
- Document installation alongside the standard ExUnit CLI formatter.
- Support Elixir 1.14 and OTP 25 as the verified baseline.
