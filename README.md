# Park Hunt

Park Hunt is an iPhone-first scavenger-hunt companion for discovering hidden details in theme parks. The prototype is intentionally small: prove the hunt loop before adding maps, accounts, ads, community features, or a backend.

## Completed efforts

### #1–#24 Core experience + tactile hunt flow

Park Hunt now supports the complete local hunt loop, offline image packaging/downsampling, progress, Collection, Settings, accessibility, one-handed controls, and restrained hunt haptics.

### #25 State restoration

Park Hunt now persists the active hunt separately from ordinary hunt progress so an interruption can return the player to the exact gameplay state.

- starting an unfinished hunt records it as the active hunt,
- reopening the app automatically returns to that unfinished discovery,
- saved clue order is restored from the existing `UserProgress` data without advancing or rewriting the clue timestamp,
- if **Show Me** was open when the app was interrupted, restoration returns through the Hunt and reopens the Reveal screen,
- dismissing Reveal updates the active session back to the Hunt screen,
- completing **I Found It** clears the active-hunt restoration target,
- deliberately backing out of an unfinished Hunt while the app is active clears the restoration target,
- removed/unavailable or already-completed discoveries are rejected as stale restoration targets,
- a transient catalog-load failure does not erase the saved restoration target,
- **Reset Hunt Progress** also clears the active-hunt session while preserving Help Style and haptics.

The active session is stored locally in `UserDefaultsActiveHuntStore`; no account or network dependency is introduced.

## Verification

CI continues to run:

```text
Verify offline core
→ Verify image assets
→ Generate Xcode project
→ Build for iOS Simulator
```

Source tests cover active-session persistence, stale/completed-session rejection, exact saved clue stage, and saved Reveal state. Full XCTest execution remains scheduled for #32.

## Next effort

**#26 Error states:** harden denied/no location, bad content, missing photo, no nearby hunts, and all-complete states with clear recovery actions.
