# Disneyland field-test build

The FieldTest build is the first real-device beta channel for the 18 New Orleans Square hunts.

## Why FieldTest is separate from Release

The current hunt batch is source-vetted but intentionally marked `needsRecheck`. Those discoveries need to be tested in Disneyland before they can become production `verified` content.

The content gates therefore have different jobs:

- `--field-test` allows `verified` and `needsRecheck`, but rejects `unverified`, development-only, development-registry, and placeholder content.
- `--shipping` rejects both `unverified` and `needsRecheck`.

The Xcode `FieldTest` configuration defines `PARKHUNT_FIELD_TEST`, uses the same optimized Release settings, and visibly labels the app as **Disneyland Field Test**.

## CI field-test archive

CI creates an unsigned device archive with:

```bash
./scripts/build-field-test.sh --ci-unsigned
```

That proves the exact FieldTest configuration, catalog, AppIcon, and generic-device archive can be built without Apple credentials.

## Signed TestFlight build

On an authorized developer Mac:

```bash
TEAM_ID=ABCDE12345 BUILD_NUMBER=2 ./scripts/build-field-test.sh signed
```

This validates field-test content, verifies the generated catalog, archives the `FieldTest` configuration, and exports an App Store Connect package.

An actual upload still requires the developer's authenticated Apple/App Store Connect session.

## In-park purpose

The field build is specifically for confirming:

- the physical detail still exists,
- the clue sequence is understandable in place,
- the final detailed hint is accurate,
- the reveal description points to the correct object,
- the approximate Nearby coordinate/radius is useful,
- indoor/outdoor metadata is correct.

#39 adds structured field-test instrumentation; #38 only ensures the build itself is packaged safely and clearly.
