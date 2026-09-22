# Park Hunt

Park Hunt is an iPhone-first scavenger-hunt companion for discovering hidden details in theme parks. The prototype is intentionally small: prove the hunt loop before adding maps, accounts, ads, community features, or a backend.

## Completed efforts

### #1–#23 Core experience + one-handed hunt flow

Park Hunt now supports the complete local hunt loop, offline image packaging/downsampling, progress, Collection, Settings, accessibility hardening, and a contextual bottom thumb tray for in-park use.

### #24 Haptics

Hunt feedback now uses a restrained tactile hierarchy instead of limiting haptics to completion.

- revealing a normal clue uses a **light impact**,
- revealing stronger/detailed help uses a **medium impact**,
- opening the full **Show Me** reveal uses a distinct **rigid impact**,
- **I Found It** keeps the stronger system **success notification** haptic.

The feedback only fires after Park Hunt has persisted the corresponding clue/reveal/found state. Reopening an already-viewed reveal does not fire a new hunt-progress haptic.

The existing Settings → Haptics toggle controls all four feedback types. When haptics are disabled, Hunt state still saves normally and no tactile feedback is generated.

A pure `HuntHapticPolicy` maps gameplay actions to semantic events and patterns, keeping UIKit feedback generation separate from game state and making the intensity hierarchy testable.

## Verification

CI continues to run:

```text
Verify offline core
→ Verify image assets
→ Generate Xcode project
→ Build for iOS Simulator
```

Source tests cover normal clue, detailed help, full reveal, and found-success haptic policy. Full XCTest execution remains scheduled for #32.

## Next effort

**#25 State restoration:** make reopening the app return cleanly to the active hunt and exact saved clue/reveal state after the app is closed or interrupted.
