# Park Hunt

Park Hunt is an iPhone-first scavenger-hunt companion for discovering hidden details in theme parks. The prototype is intentionally small: prove the hunt loop before adding maps, accounts, ads, community features, or a backend.

## Completed efforts

### #1 Project setup

- SwiftUI application
- iPhone-first target
- iOS 17.0 minimum deployment target
- Swift 6 language mode
- Bundle identifier: `com.flesentine.parkhunt`
- Feature-first source layout
- Debug and Release environment configuration
- No backend required for the prototype
- Analytics disabled by default
- XcodeGen project definition committed as source of truth
- GitHub Actions build check
- Unit-test target

### #2 Core data model

The domain layer defines discoveries, progressive hints, place/area references, verification status, and per-discovery user progress. Models are Codable and Sendable so they can support offline JSON now and asynchronous services later.

### #3 Local content storage

The app ships a versioned `content-catalog.json` resource in the application bundle. `BundledContentStore` reads the catalog locally, `ContentCatalogCodec` decodes ISO-8601 dates, and catalog validation rejects unsupported schema versions, duplicate IDs, broken land/area references, and invalid domain records.

The committed discovery entry is intentionally development-only. Production/prototype discoveries are populated in the dedicated content effort rather than copied from third-party databases.

### #4 Content loader

Features consume content through `ContentLoader` and `ContentSnapshot`, not through JSON or bundle APIs. The loader caches the first successful load, supports explicit reload/reset for future update behavior, and accepts any `ContentCatalogSource`.

The immutable snapshot builds ID indexes and provides queries for lands, attraction/areas, categories, and discoveries. Removed and temporarily unavailable discoveries are excluded from hunt-facing queries by default but remain available to administrative/history flows when explicitly requested.

### #5 Home screen

The app opens into a data-driven SwiftUI Home screen backed by `ContentLoader`. Home shows the first available prototype area, the real number of huntable discoveries, a featured discovery, and a large one-handed Start Hunt CTA.

Loading, empty, and failure states are handled explicitly. Start Hunt navigates through a lightweight discovery handoff that proves navigation/content wiring without pre-building the later full hunt experience.

### #6 Location permission flow

Home has a Nearby entry point, but the app does **not** request location on launch. Tapping Nearby first shows a contextual explanation. Only tapping **Use My Location** requests Apple's **When In Use** permission.

Denied and restricted states have clear fallback UI. Users can continue without location, and denied users can jump to Settings if they later change their mind.

### #7 Location service

Nearby now requests a **single foreground location fix** only after permission is granted. The service rejects stale or invalid readings, identifies weak accuracy, and does not continuously track the user.

A pure resolver compares the fix with offline discovery coordinates to infer the nearest known park/land and, only at closer range, attraction/area context. A 1.5 km ceiling prevents the app from labeling a distant user as being in the park simply because a park record is the nearest content. GPS failure and poor indoor accuracy have explicit retry/fallback states.

## Architecture

```text
ParkHunt/
├── App/          App entry point, environment, root composition
├── Core/
│   ├── Content/  Source → loader/cache → immutable query snapshot
│   ├── Domain/   Discovery/place/progress value types
│   └── Location/ Permission, one-shot GPS, context resolver
├── Features/
│   ├── Home/     Home presentation, screen, discovery handoff
│   └── Nearby/   Permission + current-area discovery context
└── Resources/    Offline content catalog and app assets

ParkHuntTests/    Unit tests
Config/           Build configuration
.github/          CI and pull-request conventions
```

The prototype starts with no network/backend dependency. Content/domain logic, user/game state, location permission/location service, and presentation remain separate so later efforts can evolve independently.

## Open the project on a Mac

Requirements: Xcode and Homebrew.

```bash
./bootstrap.sh
```

Or manually:

```bash
brew install xcodegen
xcodegen generate
open ParkHunt.xcodeproj
```

## Build from the command line

```bash
xcodegen generate
xcodebuild \
  -project ParkHunt.xcodeproj \
  -scheme ParkHunt \
  -configuration Debug \
  -destination 'generic/platform=iOS Simulator' \
  CODE_SIGNING_ALLOWED=NO \
  build
```

## Next effort

**#8 Manual area selection:** let users browse Disneyland → land without location, and use that same selector when permission is denied or GPS is unavailable.
