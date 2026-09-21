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

### #2–#10 Foundation

The app has an offline Codable content model and validated bundled catalog, a cached content loader/query snapshot, Home, contextual When-In-Use location permission, one-shot GPS context, manual park/land browsing, a shared nearby ranking/filter engine, and smart discovery selection that avoids completed/current hunts by default.

### #11 Hunt screen

The temporary discovery handoff has been replaced by a dedicated SwiftUI gameplay screen. It loads the selected discovery through the content layer, shows category/difficulty plus land/area context, gives the first ordered clue prominent visual priority, and reinforces the product rule to look at the park instead of the phone.

The hunt screen has explicit loading, unavailable, and catalog-failure states and keeps its active control at the bottom for easy one-handed use. It intentionally does **not** reveal later clues or persist found state yet; those behaviors belong to the following gameplay efforts.

## Architecture

```text
ParkHunt/
├── App/
├── Core/
│   ├── Content/
│   ├── Domain/
│   ├── Location/
│   └── Nearby/
├── Features/
│   ├── Home/
│   ├── Hunt/     Gameplay presentation + hunt screen
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

**#12 Progressive hint system:** reveal Clue 2 → detailed hint → full reveal in controlled steps and persist the highest hint stage viewed.
