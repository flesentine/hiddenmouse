# Park Hunt

Park Hunt is an iPhone-first scavenger-hunt companion for discovering hidden details in theme parks. The prototype is intentionally small: prove the hunt loop before adding maps, accounts, ads, community features, or a backend.

## Completed efforts

### #1–#25 Core experience + restoration

Park Hunt now supports the complete local hunt loop, offline image packaging/downsampling, progress, Collection, Settings, accessibility, one-handed controls, haptics, and active-hunt restoration.

### #26 Error states

The core experience now distinguishes recoverable failures and empty/completed states instead of collapsing them into generic blank screens.

- **Location denied** keeps manual browsing available and offers an iOS Settings shortcut.
- **Weak or unavailable location** offers retry plus manual browsing.
- **Catalog load failures** are separated from “no nearby park” and show retry actions.
- Packaged-content failures distinguish missing content, invalid catalog data, and missing required offline assets in the recovery model.
- **No nearby hunts** explains that nothing is cataloged close enough and points the guest to manual area browsing/check-again.
- **All nearby hunts complete** is shown separately from “no hunts,” while completed hunts remain available for deliberate revisit.
- Manual land browsing shows **Land Complete** when every hunt there is found, with a direct route back to choose another land.
- Empty manual land/park catalog states are explicit; catalog-load failures have retry actions.
- Collection load failures have retry, and zero-result filters offer **Clear Filters**.
- Reveal treats a missing/unreadable photo as nonfatal because the full text reveal remains available.
- A discovery removed before Reveal opens shows **Reveal Unavailable** with a direct **Back to Hunt** action.
- Home no longer advertises an already-completed first discovery after the whole current catalog is complete; it shows **All Available Hunts Found** and **Review Collection** instead.

A shared `CatalogRecoveryPresentation` and `HuntAvailabilityState` make these distinctions testable outside SwiftUI.

## Verification

CI continues to run:

```text
Verify offline core
→ Verify image assets
→ Generate Xcode project
→ Build for iOS Simulator
```

Source tests cover empty/available/all-complete hunt classification and catalog-recovery classification. Full XCTest execution remains scheduled for #32.

## Next effort

**#27 Analytics foundation:** define privacy-conscious local event instrumentation for app open, hunt start, clue/reveal, found, Find Another, and return behavior.
