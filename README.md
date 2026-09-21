# Park Hunt

Park Hunt is an iPhone-first scavenger-hunt companion for discovering hidden details in theme parks. The prototype is intentionally small: prove the hunt loop before adding maps, accounts, ads, community features, or a backend.

## Completed efforts

### #1–#15 Core hunt loop

Park Hunt now has offline validated content, Home, GPS/manual area discovery, ranked hunt selection, progressive hints, spoiler-control preferences, a dedicated Reveal screen, and persistent **I Found It** completion with haptic feedback.

### #16 Next-hunt loop

Completing a discovery now keeps the player in the hunt loop instead of forcing a trip back through Home.

The **Found It!** success card immediately evaluates the same ranked discovery system used by Nearby and offers:

- the best unfinished discovery in the same area when possible,
- then the same land,
- then another sensible hunt in the same park,
- approximate distance when both discoveries have coordinates,
- a prominent **Find Another** action.

The just-completed discovery is explicitly excluded, and completed discoveries are never selected as the automatic next hunt. When coordinates exist, recommendations are capped at 1.5 km so the app does not suggest a technically same-park record that is not reasonably nearby. If the current discovery has no coordinates, selection falls back to area/land/park context.

When no unfinished recommendation remains, the success card shows **Nearby set complete** instead of replaying an old hunt.

## Architecture

```text
ParkHunt/
├── App/
├── Core/
│   ├── Content/
│   ├── Domain/
│   ├── Feedback/
│   ├── Location/
│   ├── Nearby/   Ranking, selection, next-hunt recommendation
│   ├── Progress/
│   └── Settings/
├── Features/
│   ├── Home/
│   ├── Hunt/     Completion → Find Another loop
│   ├── Nearby/
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

**#17 Progress tracking:** expose saved completion totals, per-land/category progress, last discovery, timestamps, and overall counts as reusable progress summaries.
