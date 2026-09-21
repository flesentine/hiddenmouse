# Park Hunt

Park Hunt is an iPhone-first scavenger-hunt companion for discovering hidden details in theme parks. The prototype is intentionally small: prove the hunt loop before adding maps, accounts, ads, community features, or a backend.

## Completed efforts

### #1–#12 Foundation + progressive gameplay

Park Hunt now has offline validated content, Home, contextual foreground location, manual park/land browsing, Nearby ranking and selection, a real Hunt screen, progressive hints, text reveal, and locally persisted hunt-stage progress.

### #13 Spoiler settings

A persistent **Help Style** preference now controls how aggressively the Hunt screen offers assistance without automatically revealing anything.

- **Explorer** keeps the next help action visually secondary.
- **Normal** offers the standard next clue in the primary action.
- **Help Me** promotes the stronger detailed hint when one remains, while preserving the normal next clue as a secondary option.
- **Show Me** promotes the full reveal immediately, while preserving the normal next step as a secondary option.

Preferences are stored locally in UserDefaults and default to **Normal**. Home exposes a focused Help Style screen from the toolbar. This is intentionally narrower than the future full Settings screen, which can later absorb the same preference/store.

The underlying clue progression remains unchanged. A mode never reveals content just because it is selected; the user must still tap the corresponding action.

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
│   └── Settings/ Persistent help-style preference
├── Features/
│   ├── Home/
│   ├── Hunt/     Progression + help-style policy
│   ├── Nearby/
│   └── Settings/ Focused Help Style UI
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

**#14 Reveal screen:** turn Show Me into the dedicated exact-location/original-reference-photo experience, while keeping it behind an explicit user action.
