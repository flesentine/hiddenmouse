# Park Hunt

Park Hunt is an iPhone-first scavenger-hunt companion for discovering hidden details in theme parks. The prototype is intentionally small: prove the hunt loop before adding maps, accounts, ads, community features, or a backend.

## Completed efforts

### #1–#18 Core experience

Park Hunt now supports offline content, GPS/manual browsing, ranked hunt selection, progressive clues, spoiler controls, Reveal, persistent completion, Find Another, progress summaries, and a filterable Collection.

### #19 Settings screen

The temporary Help Style toolbar shortcut has been replaced by a full **Settings** hub.

Settings now includes:

- **Location** — current authorization status, a route into Nearby before permission is requested, and an iOS Settings shortcut when location access has already been decided.
- **Help Style** — Explorer / Normal / Help Me / Show Me using the existing persistent preference.
- **Haptics** — a persistent on/off toggle, enabled by default. The Found success haptic now respects this setting.
- **Reset Hunt Progress** — destructive confirmation before clearing found timestamps, hint progress, reveal history, and progress timestamps. Help Style and haptics are intentionally preserved.
- **Privacy & Legal** — local privacy behavior, independent-app disclosure, and content/trademark notes.
- **App version/build** — read from the installed bundle.

Settings does not request location permission by itself. The first permission prompt still occurs only through Nearby, preserving the original privacy design.

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
│   ├── Progress/
│   └── Settings/ Help style + haptics + app metadata
├── Features/
│   ├── Collection/
│   ├── Home/
│   ├── Hunt/
│   ├── Nearby/
│   ├── Progress/
│   ├── Reveal/
│   └── Settings/ Full settings + privacy/legal
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

**#20 Offline behavior:** explicitly verify and harden the core hunt experience for airplane-mode use: browsing, clues, progress, reveal content, and packaged images.
