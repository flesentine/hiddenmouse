# Park Hunt

Park Hunt is an iPhone-first scavenger-hunt companion for discovering hidden details in theme parks. The prototype is intentionally small: prove the hunt loop before adding maps, accounts, ads, community features, or a backend.

## Effort #1 — project setup

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
- Unit-test target ready for later efforts

## Architecture

```text
ParkHunt/
├── App/          App entry point, environment, root composition
├── Core/         Shared domain/services/infrastructure
├── Features/     Feature modules (Home, Hunt, Collection, etc.)
└── Resources/    Local discovery data and app assets

ParkHuntTests/    Unit tests
Config/           Build configuration
.github/          CI and pull-request conventions
```

The app starts with no network/backend dependency so the prototype can remain offline-first. Later efforts should keep content/domain logic separate from game-state logic and presentation.

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

## Configuration

`Config/Debug.xcconfig` defines `PARKHUNT_DEVELOPMENT`.

`Config/Release.xcconfig` defines `PARKHUNT_PRODUCTION`.

`AppEnvironment.current` converts those build-time conditions into the runtime environment. Secrets must never be committed; future local-only values belong in ignored `*.local.xcconfig` files or Xcode/CI secret storage.

## Next effort

**#2 Core data model:** `Discovery`, `Land`, `Attraction/Area`, `Category`, `Hint`, `Difficulty`, `Location`, `VerificationStatus`, and `UserProgress`.
