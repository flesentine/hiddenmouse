# Park Hunt

Park Hunt is an iPhone-first scavenger-hunt companion for discovering hidden details in theme parks. The prototype is intentionally small: prove the hunt loop before adding maps, accounts, ads, community features, or a backend.

## Completed efforts

### #1–#19 Core experience

Park Hunt now supports offline content, GPS/manual browsing, ranked hunt selection, progressive clues, spoiler controls, Reveal, persistent completion, Find Another, progress summaries, Collection, and a full Settings hub.

### #20 Offline behavior

The prototype's core hunt loop is now explicitly hardened for airplane-mode use.

- The discovery catalog is read only from the application bundle.
- Home, manual park/land browsing, Collection, hunts, clues, progress, settings, completion, and text reveals use local content/state only.
- Progress and preferences remain local in UserDefaults.
- Reveal photos are resolved explicitly from the application bundle through `BundledRevealImageStore`.
- If a hunt declares a `revealImageName` but that image is not actually packaged, `ContentLoader` rejects the catalog as not offline-ready instead of failing later in the Reveal UI.
- A CI check scans the app source/content and fails if core networking APIs or hard-coded HTTP(S) URLs are introduced.

The current prototype catalog does not require a reveal photo, so its text reveal remains fully usable offline. Future records that name a reveal image must package that image with the app.

The offline CI guard currently blocks `URLSession`, `URLRequest`, `AsyncImage`, Network.framework connections, Alamofire, and hard-coded HTTP(S) URLs inside `ParkHunt/`.

## Verification

The GitHub build now performs the offline-core guard before XcodeGen/project compilation. Unit-test coverage also defines offline-readiness behavior for optional images, required packaged images, and the real bundled catalog. The current GitHub workflow still builds the app target; full XCTest execution remains part of the dedicated internal-testing effort.

## Architecture

```text
ParkHunt/
├── App/
├── Core/
│   ├── Collection/
│   ├── Content/
│   ├── Domain/
│   ├── Feedback/
│   ├── Location/
│   ├── Nearby/
│   ├── Offline/   Offline readiness validation
│   ├── Progress/
│   └── Settings/
├── Features/
│   ├── Collection/
│   ├── Home/
│   ├── Hunt/
│   ├── Nearby/
│   ├── Progress/
│   ├── Reveal/
│   └── Settings/
└── Resources/

scripts/
└── verify-offline-core.sh

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
./scripts/verify-offline-core.sh
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

**#21 Image handling:** add efficient thumbnail/reveal-image packaging, sizing, and compression without changing the offline-first guarantee.
