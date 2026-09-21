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

### #4 Content loader

Features consume content through `ContentLoader` and `ContentSnapshot`, not through JSON or bundle APIs. The immutable snapshot builds ID indexes and provides queries while keeping storage details out of features.

### #5 Home screen

The app opens into a data-driven SwiftUI Home screen backed by `ContentLoader`.

### #6 Location permission flow

Nearby never asks for location on launch. The user explicitly chooses **Use My Location**, and only **When In Use** access is requested.

### #7 Location service

Nearby gets a single foreground location fix, rejects stale/poor readings, and infers approximate park/land/area context from offline discovery coordinates.

### #8 Manual area selection

Users can browse park → land → discoveries and start hunts without granting location.

### #9 Nearby discovery engine

`NearbyDiscoveryEngine` is the single ranking/filtering source for GPS and manual browsing. It accepts context plus filters for scope, difficulty, found state, and maximum distance.

### #10 Discovery selection

`DiscoverySelector` turns ranked results into one recommended next hunt. By default it selects only unfinished discoveries, skips the current discovery, and honors an explicit exclusion set. If every eligible hunt is completed, it returns no recommendation rather than silently repeating one.

Completed discoveries can only be used as a fallback when the caller explicitly chooses `.includeIfNeeded`. GPS Nearby and manual land browsing now surface a prominent **Start Suggested Hunt** action while keeping the full ranked list available underneath.

## Architecture

```text
ParkHunt/
├── App/
├── Core/
│   ├── Content/
│   ├── Domain/
│   ├── Location/
│   └── Nearby/   Ranking + smart discovery selection
├── Features/
│   ├── Home/
│   └── Nearby/
└── Resources/

ParkHuntTests/
Config/
.github/
```

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

**#11 Hunt screen:** replace the lightweight discovery handoff with the actual gameplay view: discovery context, first clue, minimal instructions, and one-handed hunt controls.
