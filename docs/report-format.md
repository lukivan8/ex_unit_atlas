# Report format

Every suite writes `ex_unit_atlas_report/report.json`. The top-level
`schema_version` allows consumers to detect future breaking schema changes.

## Schema version 1

```json
{
  "schema_version": 1,
  "generated_at": "2026-07-27T10:00:00Z",
  "summary": {
    "total": 1,
    "passed": 1,
    "failed": 0,
    "duration_us": 42000
  },
  "tests": [
    {
      "module": "Shop.SaleTest",
      "file": "test/shop/sale_test.exs",
      "line": 8,
      "describe": "Sales",
      "name": "cash sales are fiscalized",
      "status": "passed",
      "duration_us": 42000,
      "items": [
        {
          "type": "check",
          "name": "The completed cash sale is fiscalized",
          "status": "passed",
          "duration_us": 25,
          "error": null
        }
      ],
      "error": null
    }
  ]
}
```

## Guarantees

- `schema_version` is the integer `1`.
- `generated_at` is an ISO 8601 UTC timestamp.
- Durations are non-negative integers in microseconds.
- Test status is `passed` or `failed`.
- Item type is `step` or `check`.
- Item status is `passed`, `failed`, or `interrupted`.
- Tests are sorted by file, module, describe block, line, and name.
- Items preserve execution order.
- `describe` and `error` may be `null`.
- Skipped and excluded tests are omitted in schema version 1.
- Internal ownership keys are never published.

## Errors

A normalized failure has this shape:

```json
{
  "kind": "error",
  "message": "Assertion with == failed",
  "stacktrace": [
    "test/shop/sale_test.exs:18: Shop.SaleTest.\"test ...\"/1"
  ]
}
```

A test may contain more than one ExUnit failure, so the test-level `error`
field is an array. An item represents one block and therefore contains one
error object or `null`.

Consumers should ignore unknown fields for forward compatibility and should
reject unsupported `schema_version` values.
