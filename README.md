# Park Hunt

Park Hunt is an iPhone-first scavenger-hunt companion for discovering hidden details in theme parks. The prototype is intentionally small: prove the hunt loop before adding maps, accounts, ads, community features, or a backend.

## Completed efforts

### #1–#13 Foundation + spoiler-controlled gameplay

Park Hunt now has offline validated content, Home, contextual foreground location, manual park/land browsing, Nearby ranking and selection, progressive Hunt gameplay, persisted hint/reveal progress, and persistent Explorer / Normal / Help Me / Show Me help styles.

### #14 Reveal screen

**Show Me** now opens a dedicated Reveal screen instead of placing spoiler text inside the Hunt clue stack.

The Reveal screen shows:

- the discovery and park/land/area context,
- a dedicated **Exact Location** text reveal,
- an original packaged reference photo when `revealImageName` points to an available app asset,
- a clear no-photo state when verified content does not yet have an image.

Opening Show Me records `didRevealLocation` before navigation, so closing and reopening the hunt preserves that the reveal was viewed. The Hunt screen then shows **View Reveal Again** without duplicating the spoiler content inline.

Photo loading is intentionally minimal here. Compression, thumbnail strategy, and larger image-pipeline work remain in the dedicated image-handling effort.

## Architecture

```text
ParkHunt/
├── App/
├── Core/
│   ├── Content/
│   ├── Domain/
│   ├── Location/
│   ├── Nearby/
│   ├── Progress/
│   └── Settings/
├── Features/
│   ├── Home/
│   ├── Hunt/
│   ├── Nearby/
│   ├── Reveal/   Exact-location + packaged reference-photo UI
│   └── Settings/
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

**#15 Found flow:** add **I Found It**, persist completion, update progress, provide a success state, and trigger a subtle success haptic.
