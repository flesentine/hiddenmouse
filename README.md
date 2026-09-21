# Park Hunt

Park Hunt is an iPhone-first scavenger-hunt companion for discovering hidden details in theme parks. The prototype is intentionally small: prove the hunt loop before adding maps, accounts, ads, community features, or a backend.

## Completed efforts

### #1–#14 Foundation + reveal flow

Park Hunt now has offline validated content, Home, contextual foreground location, manual park/land browsing, Nearby ranking/selection, progressive Hunt gameplay, persistent help styles, saved hint/reveal state, and a dedicated full Reveal screen.

### #15 Found flow

Hunts now have a persistent **I Found It** completion action.

- Tapping **I Found It** stores the discovery's first completion time in `UserProgress.foundAt`.
- Completion is idempotent: reopening or revisiting a hunt cannot overwrite its original found timestamp.
- The Hunt screen immediately changes to a **Found It!** success state.
- A subtle success haptic fires once when the discovery is first completed.
- Reopening a completed hunt restores the success state and does not show the completion button again.
- GPS Nearby and manual land browsing now load the same persisted progress, show completed discoveries as **Found**, and avoid them when choosing **Start Suggested Hunt**.

The full ranked list still keeps completed discoveries available for deliberate replay. The next-hunt handoff after success remains the dedicated #16 effort.

## Architecture

```text
ParkHunt/
├── App/
├── Core/
│   ├── Content/
│   ├── Domain/
│   ├── Feedback/ Success haptic
│   ├── Location/
│   ├── Nearby/
│   ├── Progress/
│   └── Settings/
├── Features/
│   ├── Home/
│   ├── Hunt/     Clues, reveal state, completion
│   ├── Nearby/   Progress-aware ranking/browsing
│   ├── Reveal/
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

**#16 Next-hunt loop:** after a successful find, immediately offer the best sensible nearby unfinished discovery instead of forcing the user back through Home.
