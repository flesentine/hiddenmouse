# Park Hunt

Park Hunt is an iPhone-first scavenger-hunt companion for discovering hidden details in theme parks. The prototype is intentionally small: prove the hunt loop before adding maps, accounts, ads, community features, or a backend.

## Completed efforts

### #1–#11 Foundation + first gameplay screen

The app now has an offline validated content catalog, cached content/query layer, Home, contextual foreground location, manual park/land browsing, shared Nearby ranking, smart hunt selection, and a dedicated first-clue Hunt screen.

### #12 Progressive hint system

Hunts now reveal help in controlled stages. Ordered clue hints appear one at a time, an explicitly typed `detailed` hint can provide stronger help, and only after all hints are viewed does **Show Me** expose the text reveal. The dedicated image/exact-reference presentation remains reserved for the later reveal-screen effort.

Hint progress is local and offline. `UserProgress` records the highest hint order viewed plus whether the reveal has been opened, and `UserDefaultsUserProgressStore` persists that state. Reopening a hunt restores all previously viewed help instead of starting over. Hint progress is monotonic, so an older/lower stage can never overwrite a newer one.

The first bundled prototype record now exercises the full development ladder:

```text
Clue 1 → Clue 2 → Detailed Hint → Show Me
```

Existing content remains compatible: a hint without an explicit kind is treated as a normal clue.

## Architecture

```text
ParkHunt/
├── App/
├── Core/
│   ├── Content/
│   ├── Domain/
│   ├── Location/
│   ├── Nearby/
│   └── Progress/ Local user-progress persistence
├── Features/
│   ├── Home/
│   ├── Hunt/     Presentation + progression state machine + UI
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

**#13 Spoiler settings:** add Explorer / Normal / Help Me / Show Me preferences that control how aggressively the hunt screen offers assistance without changing the underlying clue progression.
