# Park Hunt

Park Hunt is an iPhone-first scavenger-hunt companion for discovering hidden details in theme parks. The prototype is intentionally small: prove the hunt loop before adding maps, accounts, ads, community features, or a backend.

## Completed efforts

### #1–#22 Core experience + accessibility

Park Hunt now supports the complete local hunt loop, offline image packaging/downsampling, progress, Collection, Settings, and an accessibility pass for Dynamic Type, VoiceOver, large tap targets, and non-color-only state.

### #23 One-handed UX polish

The Hunt screen’s bottom safe-area tray is now reserved only for the actions a guest is most likely to use while walking.

- The duplicate **Back to Hunts** button was removed from the thumb tray; normal iOS navigation already provides Back.
- Active hunts keep **I Found It** in the easiest bottom position with a 54 pt target.
- The most relevant help action shares the thumb row with **I Found It** on normal text sizes.
- At large Dynamic Type sizes the row stacks automatically, with **I Found It** remaining lowest/easiest to reach.
- Explorer mode’s subtle **Need Help** action is promoted into the reachable main help slot without changing what it reveals.
- Help Me / Show Me can keep one alternate, less-prominent help path above the main thumb row.
- After completion, all clue/found controls disappear and the tray becomes a single prominent **Find Another** action.
- The Found success card still previews the recommended next hunt, but no longer duplicates the button higher on the screen.
- If there is no unfinished nearby hunt, the bottom tray disappears and the success card reports **Nearby set complete**.

The behavior is represented by a pure `HuntThumbTrayState` model so active/completed action ordering can be tested independently of SwiftUI layout.

## Verification

CI continues to run:

```text
Verify offline core
→ Verify image assets
→ Generate Xcode project
→ Build for iOS Simulator
```

Source tests cover Normal, Explorer, Help Me, completed-next-hunt, and completed-with-no-next-action tray states. XCTest execution remains scheduled for #32.

## Next effort

**#24 Haptics:** keep the existing success haptic and add restrained clue/help feedback where it improves in-park interaction without becoming noisy.
