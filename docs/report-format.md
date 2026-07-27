# Report format

Every suite writes `ex_unit_atlas_report/report.json`. The top-level
`schema_version` allows consumers to detect breaking schema changes.

## Schema version 2

Schema version 2 adds `show` items with a bounded string `value`.

```json
{
  "schema_version": 2,
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
          "type": "show",
          "name": "Created sale",
          "value": "%{payment_type: :cash, status: :completed}",
          "status": "passed",
          "duration_us": 0,
          "error": null
        },
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

- `schema_version` is the integer `2`.
- `generated_at` is an ISO 8601 UTC timestamp.
- Durations are non-negative integers in microseconds.
- Test status is `passed` or `failed`.
- Item type is `step`, `show`, or `check`.
- Item status is `passed`, `failed`, or `interrupted`.
- Only `show` items contain `value`.
- A shown `value` is a bounded UTF-8 string preview, not a serialized Elixir
  term.
- Tests are sorted by file, module, describe block, line, and name.
- Items preserve execution order.
- `describe` and `error` may be `null`.
- Skipped and excluded tests are omitted.
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

## Compatibility

Schema version 1 was produced by ExUnit Atlas 0.1 and contains only `step` and
`check` items. Schema version 2 is produced from 0.2 onward and adds `show`
items plus their `value` field.

Consumers should ignore unknown fields for forward compatibility and reject
unsupported `schema_version` values.
