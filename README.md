# Park Hunt

Park Hunt is an iPhone-first scavenger-hunt companion for discovering hidden details in theme parks. The prototype is intentionally small: prove the hunt loop before adding maps, accounts, ads, community features, or a backend.

## Completed efforts

### #1–#16 Core hunt loop

Park Hunt now supports offline content, GPS/manual discovery browsing, ranked hunt selection, progressive clues, spoiler controls, full reveal, persistent completion, and the **Find Another** loop.

### #17 Progress tracking

Saved hunt state now feeds a reusable `ProgressSummary` layer rather than living only inside individual screens.

The summary reports:

- total currently huntable discoveries,
- started, found, and remaining counts,
- overall completion fraction,
- completion by land,
- completion by discovery category,
- most recent activity and its timestamp,
- most recently found discovery and its original `foundAt` timestamp,
- the persisted progress `lastUpdatedAt` timestamp.

Removed and temporarily unavailable discoveries do not inflate current completion totals. Historical progress can remain stored, but percentages are calculated against the current huntable catalog.

Home now includes a compact **Progress** card that refreshes whenever Home reappears. A dedicated Progress screen shows overall completion, land/category breakdowns, recent activity, and last-found details. This summary is intentionally reusable so the Collection screen can build on the same source in #18.

## Architecture

```text
ParkHunt/
├── App/
├── Core/
│   ├── Content/
│   ├── Domain/
│   ├── Feedback/
│   ├── Location/
│   ├── Nearby/
│   ├── Progress/ Summary + local persistence
│   └── Settings/
├── Features/
│   ├── Home/     Compact progress entry
│   ├── Hunt/
│   ├── Nearby/
│   ├── Progress/ Detailed progress overview
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

**#18 Collection screen:** browse found/unfound discoveries, filter the collection, and revisit completed finds using the same persisted progress and content snapshot.
