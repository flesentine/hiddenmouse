# Park Hunt

Park Hunt is an iPhone-first scavenger-hunt companion for discovering hidden details in theme parks. The prototype is intentionally small: prove the hunt loop before adding maps, accounts, ads, community features, or a backend.

## Completed efforts

### #1–#29 Core experience + content admin

Park Hunt now supports the full local hunt loop, offline image packaging, progress, accessibility, one-handed controls, haptics, restoration, recovery, local analytics/privacy controls, and JSON-based content administration.

### #30 Content validation tools

Content changes now go through an editorial validator before the generated catalog or Xcode build is accepted.

`scripts/validate-content-admin.py` checks:

- discovery filename/order format,
- required and unknown fields,
- stable kebab-case IDs,
- duplicate land/area/discovery/hint/tag IDs,
- discovery ID registry lifecycle,
- retired-ID reuse,
- category/difficulty/status enum values,
- park/land/area relationships,
- location coordinate/radius bounds,
- two normal clues + one final detailed hint,
- unique contiguous hint order,
- non-empty clue/reveal content,
- ISO 8601 verification dates,
- `lastVerifiedAt` for verified content,
- image filename/type/existence,
- placeholder/TODO/prototype text.

The validator has its own mutation self-tests and runs in CI before catalog synchronization.

The new `ContentAdmin/discovery-id-registry.json` gives IDs a lifecycle:

- `development`
- `active`
- `retired`

Retired IDs remain reserved and cannot be reused.

The intentional prototype fixture is explicitly marked:

```json
"_editorial": {
  "developmentOnly": true,
  "notes": "..."
}
```

Admin-only underscore fields are stripped from the generated app catalog.

Normal development validation permits that explicit fixture with warnings. Field-test and production validation are separate:

```bash
python3 scripts/validate-content-admin.py --field-test
python3 scripts/validate-content-admin.py --shipping
```

Field-test mode allows source-vetted `needsRecheck` discoveries so they can be confirmed in person, while still rejecting development-only, placeholder, and `unverified` content. Shipping mode also rejects `needsRecheck`.

### #31 Prototype content population

The development-only fixture has been replaced with **18 original New Orleans Square hunts** covering Royal Street, the Rivers of America waterfront, Pieces of Eight, the Pirates exterior area, and the expanded Haunted Mansion grounds.

The batch is source-vetted but intentionally marked `needsRecheck` until each detail and approximate Nearby coordinate is confirmed in person. Normal CI accepts the batch; `--shipping` correctly blocks it until field verification is complete.

Research provenance for the batch lives in `ContentAdmin/SOURCES.md`.

### #32 Internal testing

The existing XCTest coverage is now a required CI gate instead of dormant project coverage. Focused regression cases cover discovery selection fallbacks/exclusions, progressive hint restoration and ordering, progress persistence/reset behavior, geographic distance math, and loading the real New Orleans Square field-test catalog.

### #33 UI testing

A dedicated XCUITest target now exercises the real SwiftUI app on an iOS Simulator. The suite covers clean first launch, location-denied manual browsing, progressive clue/help/reveal flow, marking a hunt found and offering the next hunt, and restoring an unfinished hunt after termination/relaunch.

The only test hook is an explicit `--ui-location-denied` launch argument used to make Core Location deterministic under XCUITest. It is ignored during normal app launches.

### #34 Device testing

The XCUITest suite now runs as a three-profile iPhone matrix on every push and pull request:

- **compact / older-size** — prefers iPhone SE (3rd generation), iPhone 13 mini, then iPhone 16e,
- **standard** — prefers iPhone 16, then iPhone 15/14,
- **large** — prefers iPhone 16 Pro Max, then equivalent Pro Max/Plus devices.

The matrix resolves only simulators actually installed on the GitHub macOS runner and logs the selected model and iOS runtime. The compact profile prefers the oldest installed runtime when multiple runtimes are available. A dedicated UI assertion verifies the primary hunt remains reachable with normal scrolling on compact screens while the in-hunt Assist and Found thumb controls remain immediately hittable. The runner executes all three profiles even if an earlier profile fails, so one device cannot hide results from the others.

Failed device runs retain their `.xcresult` bundles as a GitHub Actions artifact for diagnosis.

### #35 Battery testing

Battery-sensitive location behavior is now a required regression gate. Park Hunt keeps Nearby intentionally lightweight:

- one foreground `requestLocation()` fix instead of continuous tracking,
- coarse 100-meter requested accuracy rather than best/navigation accuracy,
- duplicate requests are blocked while a fix is already in flight,
- explicit retry remains available after a result, weak signal, or failure,
- location is discarded when Nearby disappears or the app becomes inactive/backgrounded,
- CI rejects continuous GPS, Always authorization, background location, visit/significant-change monitoring, and high-accuracy GPS APIs.

`scripts/verify-battery-boundaries.py` enforces those source-level constraints on every push and pull request, while `LocationServiceTests` covers the runtime request policy.

Simulator CI cannot produce a trustworthy real-world battery-percentage measurement. Physical battery/thermal endurance remains a field-test measurement on the later TestFlight park build; #35 establishes the automated battery-regression boundaries that should remain true before that field test.

### #36 Performance testing

Performance now has its own CI gate instead of relying on subjective simulator feel. The suite exercises a synthetic **1,000-discovery catalog** so the code is tested well beyond the planned 75–100 discovery field-test scale.

The gate covers:

- catalog JSON decode/validation,
- indexed discovery/land/area lookups,
- Nearby ranking and distance work,
- Collection construction/sorting,
- Progress summary generation,
- repeated cold bundled-content loads recorded with XCTest clock metrics.

`ContentSnapshot` now builds immutable sorted lists and lookup/grouping indexes once at initialization. Repeated screen reads no longer re-sort lands/areas or re-filter the entire discovery catalog for common land/area/category queries.

The CI budgets are intentionally generous enough to avoid noisy runner failures while still catching order-of-magnitude regressions: three 1,000-item decodes under 3 seconds, 20,000 indexed lookup rounds under 2 seconds, and five full Nearby/Collection/Progress passes over 1,000 discoveries under 8 seconds.

Detailed rationale and reproduction guidance live in `docs/PERFORMANCE_TESTING.md`.

### #37 TestFlight setup

The repository now has a reproducible TestFlight Release path without storing Apple credentials in GitHub.

- version/build metadata lives in `Config/Version.xcconfig`,
- Release builds retain dSYMs and enable product validation,
- `Config/ExportOptions-TestFlight.plist` defines App Store Connect export behavior,
- `scripts/build-testflight-archive.sh` creates either a signed developer archive/export or an unsigned CI archive,
- `scripts/verify-testflight-readiness.py` validates bundle/version/signing/export assumptions,
- normal CI now proves a generic-device **Release archive** succeeds after all tests.

An actual TestFlight upload still requires an authorized Apple Developer/App Store Connect account. That credential boundary is documented in `docs/TESTFLIGHT.md`; credentials are intentionally not committed to the repository.

### #38 Disneyland field-test build

The first Disneyland beta channel is now packaged separately from production Release.

- `FieldTest` is a Release-optimized Xcode configuration with a dedicated `PARKHUNT_FIELD_TEST` build condition.
- The app visibly labels itself **Disneyland Field Test** in Settings and labels the Home area as a field-test area.
- `--field-test` content validation allows the 18 source-vetted `needsRecheck` New Orleans Square hunts while still rejecting unverified/development content.
- Production `--shipping` validation remains stricter and continues to reject `needsRecheck`.
- `scripts/build-field-test.sh` validates the catalog and produces the exact field-test archive.
- CI now archives both the structural production Release build and the Disneyland FieldTest build.
- A 1024×1024 AppIcon asset is included and validated, closing the remaining App Store/TestFlight packaging warning from #37.

The field-build workflow and signed-build command are documented in `docs/FIELD_TEST.md`.

### #39 Field-test instrumentation

The Disneyland FieldTest build now includes an offline, structured feedback loop directly from each hunt.

- **Accuracy** records whether the physical target is wrong, close, or accurate.
- **Clue quality** records confusing, workable, or clear.
- **Nearby usefulness** records not used, poor, okay, or useful.
- **Issue tags** cover wrong location, confusing clue, wrong reveal, poor Nearby ordering, inaccessible spots, suspected duplicates, and other issues.
- Optional notes capture the tester's park observations.
- Feedback is attached to the discovery ID/title automatically; precise coordinates are never stored.
- Records stay only on the device in UserDefaults, capped at 500 entries.
- Settings → **Field Test Feedback** shows the saved records, supports clearing them, and can share the full structured JSON for post-park review.
- Production and normal development builds do not show the in-hunt field-feedback UI.

### #40 Post-test iteration

Field-test feedback now turns into an actionable iteration queue instead of a raw log.

- Feedback is grouped by discovery.
- **Critical** priority is assigned to wrong-location, reveal-mismatch, or inaccessible-target reports.
- **High** priority is assigned to suspected duplicates or repeated confusing-clue / poor-Nearby reports.
- **Medium** priority covers single clue, Nearby, or close-location concerns.
- Clean reports remain **Monitor** items rather than creating unnecessary work.
- Each queue item includes report count, concrete reasons, and a suggested next action.
- The queue is visible in Settings → Field Test Feedback and is sorted by severity, report volume, and recency.
- Automated tests cover critical classification, repeated-problem escalation, and priority ordering.

### #41 Scale content to 75 discoveries

The Disneyland field-test catalog now contains **75 hunts across all 9 current Disneyland lands**: the 18 detailed New Orleans Square hunts plus 57 new source-vetted scale-batch hunts.

- The 57 new entries are distributed across Main Street, U.S.A., Adventureland, Frontierland, Fantasyland, Tomorrowland, Bayou Country, Mickey's Toontown, and Star Wars: Galaxy's Edge.
- Every scale-batch entry is `needsRecheck`; none is mislabeled as field-verified.
- New scale-batch entries intentionally omit GPS coordinates until an in-park tester confirms a useful Nearby location.
- Each entry has a three-stage hint progression and a stable registered discovery ID.
- Editorial source notes identify the current official Disneyland references used to confirm each venue/experience is still part of the park.
- A bundled-catalog regression test locks the target at 75 discoveries, 9 lands, and 57 scale-batch entries.

This is deliberately a **field-test scale catalog**, not a claim that all 75 hunts are release-ready. Efforts #39 and #40 provide the workflow for turning these source-vetted seeds into precise, verified hunts after in-park testing.

### #42 Map feature

Park Hunt now includes an in-app MapKit browsing screen.

- Home has a dedicated **Map** entry point.
- Only discoveries that already contain a real catalog location become map pins.
- The 57 scale-batch hunts from effort #41 remain off the map until field testing supplies a location; the app does not fabricate coordinates.
- Pins show found vs unfinished state and open the hunt directly.
- The map automatically frames the currently mapped discovery set and includes compass/scale controls.
- Browsing the map does not require live location permission because it displays catalog locations rather than tracking the guest.
- A summary shows how many hunts are mapped and how many are still awaiting field-tested locations.
- Unit coverage verifies pin eligibility, found state, and the current 18-mapped / 57-unmapped catalog split.

### #43 Search/filtering

The Collection screen now supports fast local search and composable filters across the 75-hunt catalog.

- Search matches hunt title, stable discovery ID, land name, area name, and tags.
- Existing progress-status filtering remains available for All, Found, Unfound, and Started.
- Land and category filters continue to compose with search.
- A new difficulty filter supports Easy, Medium, Hard, and Expert values present in the current catalog.
- Search and every filter can be combined at the same time.
- Clear resets the full query/filter state.
- Filtering stays fully offline and operates on the already loaded ContentSnapshot.
- Unit coverage verifies text search, difficulty filtering, composition with status/land, and available difficulty choices.

### #44 Badges/achievements

Progress now includes lightweight achievement badges based on real hunt completion rather than streaks or artificial engagement loops.

- **First Find** unlocks on the first completed hunt.
- **Getting Warm**, **Sharp Eyes**, **Detail Hunter**, and **Park Sleuth** unlock at 5, 10, 25, and 50 finds.
- **Land Complete** unlocks after every currently available hunt in any one land is found.
- **Curious Explorer** unlocks after finding hunts across 3 different discovery categories.
- Locked badges show progress toward the next threshold.
- The badge grid lives in the existing Progress screen and derives entirely from local hunt progress.
- No daily streaks, timers, penalties, or separate achievement persistence are introduced.
- Unit coverage verifies milestone thresholds, land completion, and category diversity.

### #45 Today’s Hunt / route builder

Home now includes a **Today’s Hunt** route builder for a short park session.

- Choose a 3-, 5-, or 8-hunt route.
- The builder prefers unfinished discoveries.
- When enough hunts are available, the route stays inside one land to reduce unnecessary walking.
- When one land cannot satisfy the requested length, the route expands across lands in stable park order.
- The builder does not require live GPS and works with coordinate-less field-test hunts.
- If every available hunt is already found, it still produces a replay route instead of failing.
- Each route item shows sequence, land, difficulty, and found state and opens the hunt directly.
- Unit coverage verifies unfinished preference, single-land focus, multi-land fallback, and all-found replay behavior.

### #46 Premium entitlement

Park Hunt now has a provider-agnostic premium entitlement boundary.

- Free and Premium entitlement states are modeled independently of StoreKit or any payment vendor.
- Feature access flows through a central `PremiumAccess` policy instead of scattered purchase checks.
- The basic 3-hunt Today’s Hunt route remains free.
- Premium unlocks the extended 5- and 8-hunt Today’s Hunt routes.
- Settings shows the current plan and links to a Premium screen.
- The Premium screen is intentionally a purchase placeholder until the payment provider is connected.
- Development and field-test builds include a Premium Test Override so gated UX can be exercised without purchases.
- Production does not expose that override.
- Unit coverage verifies the free default, persistence behavior, and the extended-route gate.

### #47 Advertising integration

Park Hunt now has a provider-agnostic advertising boundary designed to keep ads passive and out of gameplay.

- Ad placements are explicitly modeled for Home, Collection, Hunt, and Reveal.
- Policy permits ads only on passive browsing surfaces: **Home** and **Collection**.
- **Hunt** and **Reveal** are hard-blocked from advertising even for free users.
- Premium suppresses all ad placements and is presented as ad-free browsing.
- The advertising provider receives only the requested placement; this layer does not pass precise location, hunt history, progress, or analytics context.
- Development and field-test builds use a clearly labeled sample sponsored creative for layout testing.
- Production uses a no-op provider until a real ad network is intentionally connected.
- Sponsored cards are visibly labeled **Sponsored** and identify the sponsor.
- Unit coverage verifies premium suppression, passive free placements, active-gameplay blocking, and no-op provider behavior.

### #48 Disney California Adventure support

Park Hunt now treats Disneyland Park and Disney California Adventure as separate first-class parks.

- Added reusable park descriptors and park-scoped snapshot helpers.
- Collection can filter by park, then land/category/difficulty/status.
- Park Map can switch between Disneyland and DCA.
- Today’s Hunt can build routes inside a selected park.
- Added all 8 current DCA lands: Avengers Campus, Cars Land, Pixar Pier, San Fransokyo Square, Buena Vista Street, Grizzly Peak, Hollywood Land, and Paradise Gardens Park.
- Added one cautious `needsRecheck` field-test seed per DCA land.
- DCA seeds intentionally have no guessed coordinates or claimed hidden-detail location; they require in-park confirmation before verification.
- Multi-park tests verify park ordering, Collection isolation, Today route isolation, and Map isolation.

### #49 Cloud sync and accounts

Park Hunt now has an optional, provider-agnostic account and cloud-progress boundary while preserving local-first play.

- Existing `UserProgressStoring` remains the primary local persistence path.
- Cloud account and cloud progress providers are abstract protocols; gameplay does not depend on a specific identity or backend vendor.
- A sync coordinator merges local and remote progress rather than replacing one side blindly.
- Merge rules preserve the highest viewed hint, any reveal, the earliest found timestamp, and the latest activity timestamp.
- First sync uploads local progress when no remote record exists.
- Signed-out or unavailable cloud services never block local hunting or local saves.
- Settings shows Account & Sync status and exposes Sync Now only when a provider reports a ready account.
- Production currently uses a no-op provider until a real account/cloud backend is deliberately connected.
- Unit tests cover merge behavior, initial upload, two-way merge, signed-out behavior, and fully offline local play.

### #50 Family sharing

Park Hunt now has an optional family/group progress layer that stays separate from each person’s private hunt history.

- Family membership and shared-progress storage are provider-agnostic boundaries.
- Family sharing publishes only discovery IDs that a person has explicitly marked **Found**.
- Clue history, reveal history, found timestamps, last-viewed timestamps, precise location, and local analytics are never included in the family projection.
- Publishing family progress never mutates personal `UserProgress`.
- Shared family finds are unioned across members rather than overwriting another person’s contribution.
- Settings includes a Family entry with unavailable, no-group, and connected states.
- The Family screen shows group members, aggregate shared finds, manual publish, and manual refresh actions.
- Local/private play remains fully functional when family sharing is unavailable or unused.
- Production currently uses a no-op family provider until a real group backend is deliberately connected.
- Unit tests cover privacy projection, personal-progress isolation, union behavior, no-group behavior, and offline/unavailable behavior.

## Verification

CI now runs:

```text
Self-test content validator
→ Validate content admin
→ Validate field-test content
→ Verify content admin catalog
→ Verify offline core
→ Verify image assets
→ Verify privacy boundaries
→ Verify battery boundaries
→ Verify TestFlight readiness
→ Verify Disneyland field-test build
→ Generate Xcode project
→ Run unit tests
→ Run performance budget tests
→ Run UI tests across compact / standard / large iPhones
→ Build for iOS Simulator
→ Archive unsigned Release build
→ Archive unsigned FieldTest build
```

## Next effort

**#51 Community submissions:** add a moderated submission boundary for user-contributed hunt candidates without allowing unverified content into the trusted catalog.
