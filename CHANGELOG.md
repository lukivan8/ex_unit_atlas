# Changelog

All notable changes to this project are documented in this file. The project
uses [Semantic Versioning](https://semver.org/).

## Unreleased

## 0.1.0

First public release.

- Add `step/2` and `check/2` with preserved ExUnit failure semantics.
- Isolate events from concurrently running tests.
- Generate normalized `report.json` after passing and failing suites.
- Generate a minimal static `index.html` grouped by behavior section.
- Document installation alongside the standard ExUnit CLI formatter.
- Support Elixir 1.14 and OTP 25 as the verified baseline.
