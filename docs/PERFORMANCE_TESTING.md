# Performance testing

Park Hunt is offline-first, so the important performance path is local: decode the catalog, build indexes, rank nearby discoveries, build Collection rows, summarize progress, and move through the hunt loop without unnecessary repeated work.

## CI scale

The dedicated `PerformanceBudgetTests` suite uses a synthetic catalog with 1,000 discoveries, 20 lands, and 40 areas. That is intentionally much larger than the planned 75–100 discovery Disneyland content set so modest content growth does not push the app near its performance ceiling.

## Enforced budgets

The macOS GitHub runner must stay within these deliberately broad budgets:

- three complete 1,000-discovery JSON decode + validation passes: **< 3 seconds**
- 20,000 rounds of indexed discovery/land/area reads: **< 2 seconds**
- five complete 1,000-discovery Nearby + Collection + Progress passes: **< 8 seconds**

These are regression alarms, not product latency promises. They are wide enough to tolerate normal shared-runner noise but tight enough to catch accidental repeated full-catalog scans, pathological sorting, or loss of indexing.

The suite also records XCTest clock metrics for a real bundled cold content load. That metric is useful for comparing future CI runs even though it is not given a brittle sub-millisecond failure threshold.

## Optimization made in #36

`ContentSnapshot` now computes these immutable structures once:

- sorted lands
- sorted areas
- available discoveries
- ID lookups
- areas grouped by land
- available/all discoveries grouped by land
- available/all discoveries grouped by area
- available/all discoveries grouped by category

The public API is unchanged. Existing features keep their previous ordering and availability behavior while avoiding repeated filtering and sorting.

## Real-device follow-up

Before App Store launch, the later TestFlight field build should still be profiled on a physical iPhone for:

- cold launch to usable Home,
- Home to Hunt navigation,
- Nearby result presentation,
- Collection opening and filtering,
- memory growth over a long park session,
- thermal behavior alongside the battery checks from #35.

If a future feature changes a CI budget intentionally, update both the test and this document with the reason rather than simply widening the threshold.
