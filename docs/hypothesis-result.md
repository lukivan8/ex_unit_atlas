# Product hypothesis result

The original spike tested one product hypothesis:

> Adding named `step` and `check` blocks to regular ExUnit tests can produce a
> readable map of guaranteed behavior without weakening ExUnit's concurrency
> or failure semantics.

The technical path was verified by automated unit and integration tests. The
product evaluation used a real sales business-logic test file and a failing
integration fixture.

| Question | Result | Observation |
| --- | --- | --- |
| Are business rules understandable without opening test bodies? | Yes | Named checks expose the `all`, `only_cash`, `only_cashless`, and `disabled` rules directly. |
| Is the distinction between `step` and `check` useful? | Yes, with a caveat | It works well when one setup produces multiple contrasting guarantees. |
| Is the failure location clear? | Yes | A failed report contains the check name, assertion message, and user stacktrace frame. |
| Is the report more useful than a list of test names? | Yes | One scenario can expose several distinct guarantees, especially for cash versus cashless behavior. |
| Does the DSL force artificial fragmentation? | Sometimes | Wrapping trivial map literals can be noisy; only meaningful preparation or actions should become steps. |
| Was `show/2` necessary? | Not initially | Names and checks were sufficient for the first sales rules; later complex data flows motivated an explicit bounded preview API. |

## Decision

The core hypothesis is considered validated for the tested domain. The static
HTML report was added because the JSON offered useful information beyond test
names alone.

The main product guidance derived from dogfooding is:

> Do not add a `step` merely to make every scenario contain one. Use steps for
> meaningful actions or setup, and use checks to state guarantees.

Future features should preserve that small surface instead of turning Atlas
into an assertion framework or general observability system.

`show/2` was later added for intentional intermediate data. Logger interception
remains out of scope because it is implicit, noisy, and harder to isolate in
concurrent suites.
