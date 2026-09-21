# Park Hunt

Park Hunt is an iPhone-first scavenger-hunt companion for discovering hidden details in theme parks. The prototype is intentionally small: prove the hunt loop before adding maps, accounts, ads, community features, or a backend.

## Completed efforts

### #1–#17 Core loop + progress

Park Hunt now supports offline content, GPS/manual browsing, ranked hunt selection, progressive clues, spoiler controls, Reveal, persistent completion, Find Another, and reusable progress summaries.

### #18 Collection screen

Home now links to a dedicated **Collection** browser backed by the same offline content snapshot and persisted progress.

Every currently huntable discovery is represented as one of:

- **Found** — completed with its original found date,
- **Started** — opened or given help but not yet completed,
- **Unfound** — untouched.

Collection filters can be combined across:

- status: All / Found / Unfound / Started,
- land,
- discovery category.

The full collection stays in stable catalog order by land, area, and title. Removed and temporarily unavailable discoveries are excluded from the current collection.

Each row shows title, difficulty, land, attraction/area when available, status, and the relevant found/last-opened date. Rows remain navigable, so completed discoveries can be deliberately reopened to revisit their saved hunt and reveal state.

## Architecture

```text
ParkHunt/
├── App/
├── Core/
│   ├── Collection/ Filtered collection snapshot
│   ├── Content/
│   ├── Domain/
│   ├── Feedback/
│   ├── Location/
│   ├── Nearby/
│   ├── Progress/
│   └── Settings/
├── Features/
│   ├── Collection/ Browse + filter + revisit
│   ├── Home/
│   ├── Hunt/
│   ├── Nearby/
│   ├── Progress/
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

**#19 Settings screen:** consolidate location, Help Style, haptics, reset controls, and app/legal information into the full Settings experience.
